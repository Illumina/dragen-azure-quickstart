#!/bin/bash

set -e

# A DRAGEN license is required, and should be set as an environment variable
: "${LICENSE_URL?}"

# The resource group created by the ARM template that holds the batch account
RESOURCE_GROUP="<RESOURCE_GROUP_NAME>"
# The name of the batch account created by the ARM template
BATCH_ACCOUNT_NAME="<BATCH_ACCOUNT_NAME>"
# A unique id to assign to the batch job.
JOB_ID="<JOB_ID>"
# The pool id of the batch bool created by the ARM template.
POOL_ID="<POOL_ID>"
# The name of the storage account the outputFiles will be placed in.
# This can be the storage account created by the ARM template.
BATCH_SA="<STORAGE ACCOUNT NAME>"
# The name of the container under the storage account to place the outputFiles in.
BATCH_C="<STORAGE ACCOUNT CONTAINER NAME>"
# Set a short window for an expiration date for the SAS token to
# access the storage container.  Example: 2018-01-01T00:00:00Z
SAS_EXPIRATION="<EXPIRATION DATE>"

# Genomic hash-table tarball
GENOME_URL="https://webdata.illumina.com/downloads/software/dragen/references/genome-files/hg38-alt_masked.cnv.graph.hla.rna-9-r3.0-1.tar"
# FastQ Sample 1
FASTQ_1="https://ilmn-dragen-giab-samples.s3.amazonaws.com/WGS/precisionFDA_v2_HG002/HG002.novaseq.pcr-free.35x.R1.fastq.gz"
# FastQ Sample 2
FASTQ_2="https://ilmn-dragen-giab-samples.s3.amazonaws.com/WGS/precisionFDA_v2_HG002/HG002.novaseq.pcr-free.35x.R2.fastq.gz"
# Associated RGSM
RGSM="NA24385-AJ-Son-R1-NS_S33"
# A unique id to assign to the batch task.
TASK_ID="<TASK_ID>"

REF_DIR="dragen"
OUT_DIR="output"

# Set command to run on batch node
COMMAND=$(cat <<EOF
/bin/bash -c \
'mkdir $REF_DIR $OUT_DIR; \
tar xvf dragen.tar -C $REF_DIR; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r $REF_DIR \
    -1 fq1.gz \
    -2 fq2.gz \
    --RGID $RGSM \
    --RGSM $RGSM \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix dragen-batch \
    --enable-map-align true \
    --output-format BAM \
    --output-directory $OUT_DIR \
    --enable-variant-caller true \
    --lic-server $LICENSE_URL'
EOF
)

# Authenticate with the batch account
az batch account login \
    -n "$BATCH_ACCOUNT_NAME" \
    -g "$RESOURCE_GROUP"

# Create a job
az batch job create \
    --id $JOB_ID \
    --pool-id $POOL_ID

# Generate SAS token for container
CONTAINER_SAS="$(az storage container generate-sas \
    --name $BATCH_C \
    --account-name $BATCH_SA \
    --expiry $SAS_EXPIRATION \
    --permissions aclrw \
    --https-only \
    --output tsv)"
CONTAINER_URL="https://$BATCH_SA.blob.core.windows.net/$BATCH_C?$CONTAINER_SAS"

# Generate task json
$(cat << EOF > task.json
{
    "id": "$TASK_ID",
    "commandLine": "$COMMAND",
    "resourceFiles": [{
        "filePath": "dragen.tar",
        "httpUrl": "$GENOME_URL"
    }, {
        "filePath": "fq1.gz",
        "httpUrl": "$FASTQ_1"
    }, {
        "filePath": "fq2.gz",
        "httpUrl": "$FASTQ_2"
    }],
    "outputFiles": [{
        "filePattern": "../stdout.txt",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "$TASK_ID/stdout.txt"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "../stderr.txt",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "$TASK_ID/stderr.txt"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "$OUT_DIR/**/*",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "$TASK_ID/$OUT_DIR"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "/var/log/dragen.log",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "$TASK_ID/log/dragen.log"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "/var/log/dragen/**/*",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "$TASK_ID/log/dragen"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }]
}
EOF
)

# Create a task within the job. Set environment variables, command, and resource
# files to be used.
az batch task create \
    --job-id $JOB_ID \
    --json-file task.json
