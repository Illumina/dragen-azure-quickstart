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

Once authenticated, the next step is to create a batch job using the following variables:

* JOB_ID: A unique id to assign to the job being created.
* POOL_ID: The name of the pool created with the provided ARM template.

```sh
az batch job create --id <JOB_ID> --pool-id <POOL_ID>
```

### Create Batch Task

Once the batch job has been created, a task can be added to it.  This can be done using the JOB_ID and
a task.json specification file:

* JOB_ID: The same job id used when creating the batch job.
* JSON_FILE: A file that defines a task in JSON format.

#### Batch Command

The command passed to the batch task is what will run once the batch task
starts.  The following is an example that will run a series of commands
using bash.

This example takes advantage of bash to execute commands, as well as make sure that
[environment variables](https://docs.microsoft.com/en-us/azure/batch/batch-compute-node-environment-variables#environment-variable-visibility)
are available.  The following are example environment variables and bash command:

* REF_DIR: The directory to untar the genome hash table to.
* OUT_DIR: The directory to write the DRAGEN results to.
* FQ1: The path to the first local FASTQ file on the node.
* FQ2: The path to the second local FASTQ file on the node.
* RGID: The RGID associated with this DRAGEN run.
* RGSM: THE RGSM associated with this DRAGEN run.
* OUTPUT_PREFIX: The prefix that will be used for the DRAGEN output files.
* LICENSE: The DRAGEN license.

```bash
/bin/bash -c \
"mkdir <REF_DIR> <OUT_DIR>; \
tar xvf dragen.tar -C <REF_DIR>; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r <REF_DIR> \
    -1 <FQ1> \
    -2 <FQ2> \
    --RGID <RGID> \
    --RGSM <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix <OUTPUT_PREFIX> \
    --enable-map-align true \
    --output-format BAM \
    --output-directory <OUT_DIR> \
    --enable-variant-caller true \
    --lic-server <LICENSE>"
```

#### SAS

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
CONTAINER_URL="https://<STORAGE_ACCOUNT>.blob.core.windows.net/<CONTAINER>?<SAS_TOKEN>"
```

* [SAS CLI Reference](https://docs.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest#az_storage_blob_generate_sas)

#### Resource Files

In this example, both the genome file and the FASTQ files need to be on the
batch node when running the batch command.  This script takes advantage of the
`resourceFiles` configuration to facilitate this.

If the genome tarball and FASTQ files are in a private blob storage account, a
[SAS token](#sas) will need to be generated to allow batch to download the file.

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

* [Resource Files Reference](https://docs.microsoft.com/en-us/azure/batch/resource-files#single-resource-file-from-web-endpoint)

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

#### Create Task

With the command generated to run within the task, and accessible URLs
generated for the genome tarball and FASTQ files, the following command
can be used to create the batch task:

The following URLs must either be public, or private but made accessible
(for example, with a SAS token):

* GENOME_URL: URL of a genome tarball.
* FQ1_URL: URL of the first FASTQ file.
* FQ2_URL: URL of the second FASTQ file.

```sh
az batch task create \
    --job-id <JOB_ID> \
    --json-file task.json
```

* [Batch task create CLI reference](https://docs.microsoft.com/en-us/cli/azure/batch/task?view=azure-cli-latest#az_batch_task_create)

#### Working Example

##### Batch Job Create

```sh
az batch job create --id job1 --pool-id mypool
```

##### Create `$COMMAND`

The following command line string is assigned to the `$COMMAND` variable.

##### `$COMMAND` Variable

```bash
COMMAND=$(cat <<EOF

/bin/bash -c \
"mkdir dragen output; \
tar xvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r dragen \
    -1 1.fq.gz \
    -2 2.fq.gz \
    --RGID NA24385-AJ-Son-R1-NS_S33 \
    --RGSM NA24385-AJ-Son-R1-NS_S33 \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix NA24385-AJ-Son-R1-NS_S33 \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"

EOF
)
```

This one-liner achieves the following:

1. Sets up Genome and Output directories
1. Unarchives the genome file
1. Runs a partial reconfig on the FPGA
1. Runs DRAGEN

The `$COMMAND` variable is now interpolated in the `task.json` file below.

##### Create task.json

```json
{
    "id": "task1",
    "commandLine": "$COMMAND",
    "resourceFiles": [{
        "filePath": "dragen.tar",
        "httpUrl": "https://dragentestdata.blob.core.windows.net/reference-genomes/Hsapiens/hash-tables/hg38-alt_masked.cnv.graph.hla.rna-9-r3.0-1.tar"
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

##### Batch Task Create

```sh
az batch task create \
    --job-id job1 \
    --json-file task.json
```

#### File Streaming

While it is always necessary to have the genome file saved locally on the node, DRAGEN can stream input FASTQ files and
BAMs from private Azure Blob containers for faster processing. DRAGEN does not currently support streaming from public
Blob containers.

Blob storage authentication has been improved with DRAGEN v3.10. Credential management is now controlled via environment
variables used in the Azure SDK, allowing support for Azure SAS streaming and BLOB identity-based credential management.
Support for Azure managed identity authentication was introduced with v3.10.

Starting with DRAGEN v3.10, the need for and use of the "~/.azure-credentials" file for input streaming has been
deprecated. New environment variables were introduced for input streaming. Environment variables remove the
need for file parsing logic. Using access keys will improve security since the key will only live in memory.

DRAGEN v3.10 supports two cases for Azure authentication:

* Storage account access keys
* Managed identities

When using storage account access keys for authentication, DRAGEN can read from Azure Blob storage regardless of whether
it is run on or off Azure. To use this method of authentication, "AZ_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" and
"AZ_ACCOUNT_KEY=$STORAGE_ACCOUNT_KEY" environment variables must precede the DRAGEN invocation on the command line,
e.g.:

```sh
sudo AZ_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME AZ_ACCOUNT_KEY=$STORAGE_ACCOUNT_KEY \
/opt/edico/bin/dragen -f -r $ref \
-1 'https://myaccount.blob.core.windows.net/mycontainer/myblob/sample_S1_L001_R1_001.fastq.gz' \
-2 'https://myaccount.blob.core.windows.net/mycontainer/myblob/sample_S1_L001_R2_001.fastq.gz' \
...
```

Authentication with
[managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview#managed-identity-types)
is only available to DRAGEN when run on Azure. The DRAGEN VMs must have Contributor permissions (read/write) to the
Storage Account that it wants to read from using managed identities authentication. In order to grant these permissions
to a VM, a managed identity is needed. System-assigned managed identities can be assigned during creation of a VM or to
existing VMs using either the
[Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm#system-assigned-managed-identity)
or [Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#system-assigned-managed-identity).
User-assigned managed identities can also be assigned during creation of a VM if the
[Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity)
is used for creation. However, user-assigned managed identities cannot be assigned at time of creation to VMs that are
created using the portal. Assignment of user-assigned managed identities to portal-created VMs can only be performed
after creation of the VM. In this case, the user-assigned managed identity must first be created using the
[portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp#create-a-user-assigned-managed-identity)
or [CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azcli#create-a-user-assigned-managed-identity-1)
before being assigned to an existing VM, which can also be performed either with the
[portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm#assign-a-user-assigned-managed-identity-to-an-existing-vm)
or [CLI.](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#assign-a-user-assigned-managed-identity-to-an-existing-azure-vm)
After assigning a managed identity to a VM, it must be granted permission to a storage account using either the
[portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/howto-assign-access-portal)
or [CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/howto-assign-access-cli).

If a single managed identity exists on a VM, only the "AZ_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" environment
variable is required to stream inputs with DRAGEN. For VMs with multiple managed identities, the
"AZR_IDENT_CLIENT_ID=$IDENTITY_CLIENT_ID" environment variable with the client id of the managed identity that can access the
storage container must also be specified. To use managed identities authentication, these environment variables must
precede the DRAGEN invocation on the command line, e.g. (for a VM with multiple managed identities):

```sh
sudo AZ_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME AZR_IDENT_CLIENT_ID=$IDENTITY_CLIENT_ID \
/opt/edico/bin/dragen -f -r $ref \
-1 'https://myaccount.blob.core.windows.net/mycontainer/myblob/sample_S1_L001_R1_001.fastq.gz' \
-2 'https://myaccount.blob.core.windows.net/mycontainer/myblob/sample_S1_L001_R2_001.fastq.gz' \
...
```

##### Stream from Azure Blob Storage

The following parameters are needed for streaming from Blob storage using storage account access keys:

* STORAGE_ACCOUNT_NAME: The name of the blob storage account.
* STORAGE_ACCOUNT_KEY: An access key to the storage account.
* FQ1_URL: The full URL to the first FASTQ file in Azure Blob Storage.
* FQ2_URL: The full URL to the second FASTQ file in Azure Blob Storage.

##### `$COMMAND` Variable for Streaming FASTQ Inputs with Storage Account Access Key

The following is an example `$COMMAND` variable that streams FASTQ inputs from Blob storage using a storage account
access key:

```bash
COMMAND=$(cat <<EOF

/bin/bash -c \
"mkdir dragen output; \
tar xvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
AZ_ACCOUNT_NAME=<STORAGE_ACCOUNT_NAME> \
AZ_ACCOUNT_KEY=<STORAGE_ACCOUNT_KEY> \
/opt/edico/bin/dragen -f -r dragen \
    -1 <FQ1_URL> \
    -2 <FQ2_URL> \
    --RGID <RGID> \
    --RGSM <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix <OUTPUT_PREFIX> \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"

EOF
)
```

The following parameters are needed for streaming from Blob storage using Azure managed identities authentication:

* STORAGE_ACCOUNT_NAME: The name of the blob storage account.
* IDENTITY_CLIENT_ID: The client id of the managed identity that can access the storage container. (Only required for
VMs with multiple managed identities.)
* FQ1_URL: The full URL to the first FASTQ file in Azure Blob Storage.
* FQ2_URL: The full URL to the second FASTQ file in Azure Blob Storage.

##### `$COMMAND` Variable for Streaming FASTQ Inputs with Managed Identities

The following is an example `$COMMAND` variable that streams FASTQ inputs from Blob storage using a VM with more than
one managed identities:

```bash
COMMAND=$(cat <<EOF

/bin/bash -c \
"mkdir dragen output; \
tar xvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
AZ_ACCOUNT_NAME=<STORAGE_ACCOUNT_NAME> \
AZR_IDENT_CLIENT_ID=<IDENTITY_CLIENT_ID> \
/opt/edico/bin/dragen -f -r dragen \
    -1 <FQ1_URL> \
    -2 <FQ2_URL> \
    --RGID <RGID> \
    --RGSM <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix <OUTPUT_PREFIX> \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"

EOF
)
```

The above examples achieve the same as the `$COMMAND` [before](#command-variable) with the addition of the
environment variables required for streaming inputs from Blob storage: AZ_ACCOUNT_NAME and AZ_ACCESS_KEY or
AZ_ACCOUNT_NAME and AZR_IDENT_CLIENT_ID.

In these cases, the FASTQ files will no longer need to be referenced in the resourceFiles in the task.json

##### FASTQ List

If using a FASTQ list file to reference and stream FASTQ files, the FASTQ list file must
also be local to the node.  The FASTQ files referenced in the FASTQ list can be in the form of URLs
to files on an Azure Storage Account, in which case, the FASTQs will be streamed by DRAGEN.

The following is an example of streaming inputs with a FASTQ list using the
resourceFiles configuration as well as a SAS token to access the FASTQ list file in Azure Blob Storage.
This is stored as the [`$LIST_URL`](#list_url-for-input-streaming) variable.

##### `$LIST_URL` for Input Streaming

```bash
LIST_URL=$(az storage blob generate-sas \
    --name <FASTQ_LIST_BLOB_PATH> \
    --account-name <STORAGE_ACCOUNT> \
    --account-key <STORAGE_ACCOUNT_KEY> \
    --container-name <CONTAINER_NAME> \
    --expiry <EXPIRE_DATE> \
    --permissions r \
    --https \
    --full-uri \
    --output tsv)
```

In this example, the FASTQ files will be streamed from Azure Blob Storage using a storage account access key. Hence, we
will once again need the AZ_ACCOUNT_NAME and AZ_ACCESS_KEY environment variables in the $COMMAND Variable. If using
managed identities to stream the FASTQ files, use the AZ_ACCOUNT_NAME (for VMs with a single managed identity) or
AZ_ACCOUNT_NAME and AZR_IDENT_CLIENT_ID (for VMs with multiple managed identities), instead.

##### `$COMMAND` Variable for Input Streaming with FASTQ List and Storage Account Access Key

```bash
COMMAND=$(cat <<EOF

/bin/bash -c \
"mkdir dragen output; \
tar xvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
AZ_ACCOUNT_NAME=<STORAGE_ACCOUNT_NAME> \
AZ_ACCOUNT_KEY=<STORAGE_ACCOUNT_KEY> \
/opt/edico/bin/dragen -f -r dragen \
    --fastq-list fastq_list.csv \
    --fastq-list-sample-id <RGSM> \
    --enable-bam-indexing true \
    --enable-map-align-output true \
    --enable-sort true \
    --output-file-prefix <OUTPUT_PREFIX> \
    --enable-map-align true \
    --output-format BAM \
    --output-directory output \
    --enable-variant-caller true \
    --lic-server <LICENSE>"

EOF
)
```

##### task.json resourceFiles for FASTQ List Input

```json
"resourceFiles": [{
    "filePath": "dragen.tar",
    "httpUrl": "$GENOME_URL"
}, {
    "filePath": "fastq_list.csv",
    "httpUrl": "$LIST_URL"
}]
```

##### Example Bash Script

An [example bash script](./create-batch-task.sh) using some of the commands shown above is available for reference.
There is a required `LICENSE_URL` environment variable, as well as some variables within the script
that must be set before running it, ie:

```sh
LICENSE_URL=https://<username>:<password>@license.edicogenome.com ./create-batch-task.sh
```

There are accompanying comments within the bash script to help set these.
