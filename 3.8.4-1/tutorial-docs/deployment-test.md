Once your batch account infrastructure has been created, the following guide
can be used to create batch jobs and tasks.  This guide makes use of the
Azure CLI.

### Azure CLI Authentication

The first step is to make sure you are
[authenticated](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
through [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli),
and using the subscription in which your batch account has been provisioned.

### Batch Account Login

You will need to authenticate with the provisioned batch account in order to
create jobs and tasks.

```sh
az batch account login -n <batch account name> -g <resource group name>
```

### Create Batch Job

Once authenticated, the next step is to create a batch job.

* JOB_ID: A unique id to assign to the job being created.
* POOL_ID: The name of the pool created with the provided ARM template.

```sh
az batch job create --id <JOB_ID> pool-id <POOL_ID>
```

### Create Batch Task

Once the batch job has been created, a task can be added to it.  We will
be doing this through a task.json specification file.

* JOB_ID: The same job id used when creating the batch job.
* TASK_ID: A unique task id to assign to the task being created.

#### Batch Command

The command passed to the batch task is what will run once the batch task
starts.  The following is an example that will run a series of commands
using bash.

* REF_DIR: The directory to untar the genome hash table to.
* OUT_DIR: The directory to write the DRAGEN results to.
* FQ1: The path to the first local FASTQ file on the node.
* FQ2: The path to the second local FASTQ file on the node.
* RGID: The RGID associated with this DRAGEN run.
* RGSM: THE RGSM associated with this DRAGEN run.
* LICENSE: The DRAGEN license.

```bash
/bin/bash -c \
"mkdir <REF_DIR> <OUT_DIR>; \
tar xzvf dragen.tar -C <REF_DIR>; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r <REF_DIR> \
    -1 <FQ1> \
    -2 <FQ2> \
    --RGID <RGID> \
    --RGSM <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix dragen-batch \
    --enable-map-align true \
    --output-format BAM \
    --output-directory <OUT_DIR> \
    --enable-variant-caller true \
    --lic-server <LICENSE>"
```

#### SAS

* [SAS CLI Reference](https://docs.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest#az_storage_blob_generate_sas)

The following example will generate a full URL with SAS token to access a
file in a private blob storage account.  This is useful when wanting to
obtain read access to a specific file in a protected storage account.

* BLOB_PATH: The path to the file within the container.
* STORAGE_ACCOUNT: The name of the blob storage account.
* STORAGE_ACCOUNT_KEY: An access key to the storage account.
* EXPIRE_DATE: The datetime when the SAS token should expire.

```sh
az storage blob generate-sas \
    --name <BLOB_PATH> \
    --account-name <STORAGE_ACCOUNT> \
    --account-key <STORAGE_ACCOUNT_KEY> \
    --container-name <CONTAINER_NAME> \
    --expiry <EXPIRE_DATE> \
    --permissions r \
    --https \
    --full-uri \
    --output tsv
```

If obtaining write access to a container within a storage account is
necessary, a slightly different command can be used.

```sh
az storage container generate-sas \
    --name <CONTAINER_NAME> \
    --account-name <STORAGE_ACCOUNT> \
    --expiry <EXPIRE_DATE> \
    --permissions aclrw \
    --https-only \
    --output tsv
```

In this case, the SAS token returned by the command will need to be
appended to the container URL, for example:

```sh
CONTAINER_URL="https://<STORAGE_ACCOUNT>.blob.core.windows.net/<CONTAINER>?<SAS_TOKEN>
```

#### Resource Files

* [Resource Files Reference](https://docs.microsoft.com/en-us/azure/batch/resource-files#single-resource-file-from-web-endpoint)

In this example, both the genome file and the FASTQ files need to be on the
batch node when running the batch command.  This script takes advantage of the
`resourceFiles` configuration to facilitate this.

If the genome tarball and FASTQ files are in a private blob storage account, a
SAS token will need to be generated to allow batch to download the file.

```json
"resourceFiles": [{
    "filePath": "dragen.tar",
    "httpUrl": "$GENOME_URL"
}, {
    "filePath": "1.fq.gz",
    "httpUrl": "$FQ1_URL"
}, {
    "filePath": "2.fq.gz",
    "httpUrl": "$FQ2_URL"
}]
```

#### Output Files

Output files configuration tells batch tasks to write certain files to external
locations, triggered by certain events.  We will use this feature in this example
to get various logs and DRAGEN output out to our storage container at the end
of the run.

* CONTAINER_URL: The container url generated above with the SAS token appended to it.
* TASK_ID: A task id, used in this case to organize the output.
* OUT_DIR: The directory the DRAGEN results were written to.

```json
"outputFiles": [{
    "filePattern": "../stdout.txt",
    "destination": {
        "container": {
            "containerUrl": "<CONTAINER_URL>",
            "path": "<TASK_ID>/stdout.txt"
        }
    },
    "uploadOptions": {
        "uploadCondition": "taskcompletion"
    }
}, {
    "filePattern": "../stderr.txt",
    "destination": {
        "container": {
            "containerUrl": "<CONTAINER_URL>",
            "path": "<TASK_ID>/stderr.txt"
        }
    },
    "uploadOptions": {
        "uploadCondition": "taskcompletion"
    }
}, {
    "filePattern": "<OUT_DIR>/**/*",
    "destination": {
        "container": {
            "containerUrl": "<CONTAINER_URL>",
            "path": "<TASK_ID>/<OUT_DIR>"
        }
    },
    "uploadOptions": {
        "uploadCondition": "taskcompletion"
    }
}, {
    "filePattern": "/var/log/dragen.log",
    "destination": {
        "container": {
            "containerUrl": "<CONTAINER_URL>",
            "path": "<TASK_ID>/log/dragen.log"
        }
    },
    "uploadOptions": {
        "uploadCondition": "taskcompletion"
    }
}, {
    "filePattern": "/var/log/dragen/**/*",
    "destination": {
        "container": {
            "containerUrl": "<CONTAINER_URL>",
            "path": "<TASK_ID>/log/dragen"
        }
    },
    "uploadOptions": {
        "uploadCondition": "taskcompletion"
    }
}]
```

#### task.json

The overall structure of the task.json will look like the following,
with each of the sections described in detail above.

```json
{
    "id": "<TASK_ID>",
    "commandLine": "<COMMAND>",
    "resourcesFiles": [<RESOURCE_FILES>],
    "outputFiles": [<OUTPUT_FILES>]
}
```

#### Create

* [Batch task create CLI reference](https://docs.microsoft.com/en-us/cli/azure/batch/task?view=azure-cli-latest#az_batch_task_create)

With the command generated to run within the task, and accessible URLs
generated for the genome tarball and FASTQ files, the following command
can be used to create the batch task.

The below URLs must either be public, or private but made accessible
(for example, with a SAS token).

* GENOME_URL: URL of a genome tarball.
* FQ1_URL: URL of the first FASTQ file.
* FQ2_URL: URL of the second FASTQ file.

```sh
az batch task create \
    --job-id <JOB_ID> \
    --json-file task.json
```

#### Working Example

TODO: Fill in public genome url, fastq urls, and associated RGID and RGSM

```sh
az batch job create --id job1 pool-id mypool
```

`COMMAND=`

```bash
/bin/bash -c \
"mkdir dragen output; \
tar xzvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r dragen \
    -1 1.fq.gz \
    -2 2.fq.gz \
    --RGID NA24385-AJ-Son-R1-NS_S33 \
    --RGSM NA24385-AJ-Son-R1-NS_S33 \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix dragen-batch \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"
```

task.json

```json
{
    "id": "task1",
    "commandLine": "$COMMAND",
    "resourceFiles": [{
        "filePath": "dragen.tar",
        "httpUrl": "https://dragentestdata.blob.core.windows.net/reference-genomes/Hsapiens/hash-tables/hg38_altaware_nohla-cnv-anchored.v8.tar"
    }, {
        "filePath": "1.fq.gz",
        "httpUrl": "https://dragentestdata.blob.core.windows.net/samples/wes/NA24385-AJ-Son-R1-NS_S33/NA24385-AJ-Son-R1-NS_S33_L001_R1_001.fastq.gz"
    }, {
        "filePath": "2.fq.gz",
        "httpUrl": "https://dragentestdata.blob.core.windows.net/samples/wes/NA24385-AJ-Son-R1-NS_S33/NA24385-AJ-Son-R1-NS_S33_L001_R2_001.fastq.gz"
    }],
    "outputFiles": [{
        "filePattern": "../stdout.txt",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "task1/stdout.txt"
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
                "path": "task1/stderr.txt"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "output/**/*",
        "destination": {
            "container": {
                "containerUrl": "$CONTAINER_URL",
                "path": "task1/output"
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
                "path": "task1/log/dragen.log"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }, {
        "filePattern": "/var/log/dragen/**/*",
        "destination": {
            "container": {
                "containerUrl": "<CONTAINER_URL>",
                "path": "task1/log/dragen"
            }
        },
        "uploadOptions": {
            "uploadCondition": "taskcompletion"
        }
    }]
}
```

```sh
az batch task create \
    --job-id job1 \
    --json-file task.json
```

#### File Streaming

While it is always necessary to have the genome file locally on the node, DRAGEN
can stream input FASTQ files and BAMs from private Azure Blob containers for faster
processing.  DRAGEN does not currently support streaming from public Blob containers.

##### Stream from Azure Blob Storage

* STORAGE_ACCOUNT: The name of the blob storage account.
* STORAGE_ACCOUNT_KEY: An access key to the storage account.
* FQ1_URL: The full URL to the first FASTQ file in Azure Blob Storage.
* FQ2_URL: The full URL to the second FASTQ file in Azure Blob Storage.

`COMMAND=`

```bash
/bin/bash -c \
"echo DefaultEndpointsProtocol=https >> ~/.azure-credentials; \
echo AccountName=<STORAGE_ACCOUNT_NAME> >> ~/.azure-credentials; \
echo AccountKey=<STORAGE_ACCOUNT_KEY> >> ~/.azure-credentials; \
echo EndpointSuffix=core.windows.net >> ~/.azure-credentials; \
mkdir dragen output; \
tar xzvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r dragen \
    -1 <FQ1_URL> \
    -2 <FQ2_URL> \
    --RGID <RGID> \
    --RGSM <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix dragen-batch \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"
```

In this case, the FASTQ files will no longer need to be referenced in the
resourceFiles in the task.json

```sh
az batch task create \
    --job-id <JOB_ID> \
    --json-file task.json
```

##### FASTQ List

If using a FASTQ list file to reference and stream FASTQ files, the FASTQ list file must
also be local to the node.  The FASTQ files referenced in the FASTQ list can be URLs
to files on an Azure Storage Account, in which case, the FASTQs will be streamed by DRAGEN.
The below example shows an example of this using the
resourceFiles configuration as well as a SAS token to access the file in Azure Blob Storage.

Since we are streaming from Azure Blob Storage, we will need the `~/.azure-credentials` file
again.

`LIST_URL=`

```sh
az storage blob generate-sas \
    --name <FASTQ_LIST_BLOB_PATH> \
    --account-name <STORAGE_ACCOUNT> \
    --account-key <STORAGE_ACCOUNT_KEY> \
    --container-name <CONTAINER_NAME> \
    --expiry <EXPIRE_DATE> \
    --permissions r \
    --https \
    --full-uri \
    --output tsv
```

`COMMAND=`

```bash
/bin/bash -c \
"echo DefaultEndpointsProtocol=https >> ~/.azure-credentials; \
echo AccountName=<STORAGE_ACCOUNT_NAME> >> ~/.azure-credentials; \
echo AccountKey=<STORAGE_ACCOUNT_KEY> >> ~/.azure-credentials; \
echo EndpointSuffix=core.windows.net >> ~/.azure-credentials; \
mkdir dragen output; \
tar xvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r dragen \
    --fastq-list fastq_list.csv \
    --fastq-list-sample-id <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix dragen-batch \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"
```

task.json resourceFiles:

```json
"resourceFiles": [{
    "filePath": "dragen.tar",
    "httpUrl": "$GENOME_URL"
}, {
    "filePath": "fastq_list.csv",
    "httpUrl": "$LIST_URL"
}]
```

```sh
az batch task create \
    --job-id <JOB_ID> \
    --json-file task.json
```

##### Example Bash Script

An [example bash script](../docs-create-task.sh) using the above commands is available for reference.
There is a required `LICENSE_URL` environment variable, as well as some variables within the script
that must be set before running it, ie:

```sh
LICENSE_URL=https://<username>:<password>@license.edico.com ./create-batch-task.sh
```

There are accompanying comments within the bash script to help set these.
