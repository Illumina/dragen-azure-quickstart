## Test the Deployment using the Azure CLI

Once your batch account infrastructure has been created, the following guide
can be used to create batch jobs and tasks.  The following guide makes use
of the Azure CLI.

### Azure CLI Authentication

The first step is to make sure you are
[authenticated](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
through [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli),
and using the subscription in which your batch account has been provisioned.

### Batch Account Login

You will need to authenticate with the provisioned batch account in order to
create jobs and tasks.

```sh
> az batch account login -n <batch account name> -g <resource group name>
```

### Create Batch Job

Once authenticated, the next step is to create a batch job.

* JOB_ID: A unique id to assign to the job being created.
* POOL_ID: The name of the pool created with the provided ARM template.

```sh
az batch job create --id <JOB_ID> pool-id <POOL_ID>
```

### Create Batch Task

Once the batch job has been created, a task can be added to it.

* JOB_ID: The same job id used when creating the batch job.
* TASK_ID: A unique task id to assign to the task being created.

#### Batch Command

The command passed to the batch task is what will run once the batch task
starts.  The following is an example that will run a series of commands
using bash.

* REF_DIR: The directory to untar the genome hash table to.
* OUT_DIR: The directory to write the DRAGEN results to.
* FQ1: The path to the first local FastQ file on the node.
* FQ2: The path to the second local FastQ file on the node.
* RGID: The RGID associated with this DRAGEN run.
* RGSM: THE RGSM associated with this DRAGEN run.
* LICENSE: The DRAGEN license.

```bash
/bin/bash -c \
'mkdir <REF_DIR> <OUT_DIR>; \
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
    --lic-server <LICENSE>
```

#### Resource Files

* [Resource Files Reference](https://docs.microsoft.com/en-us/azure/batch/resource-files#single-resource-file-from-web-endpoint)

In this example, both the genome file and the FastQ list file need to be on the
batch node when running the batch command.  This script takes advantage of the
`--resources-files` batch task option to facilitate this.

If the genome tar and FastQ files are in a private blob storage account, a
SAS token will need to be generated to allow batch to download the file.

##### SAS

* [SAS CLI Reference](https://docs.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest#az_storage_blob_generate_sas)

The following example will generate a full URL with SAS token to access a
file in a private blob storage account.

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

#### Create

* [Batch task create CLI reference](https://docs.microsoft.com/en-us/cli/azure/batch/task?view=azure-cli-latest#az_batch_task_create)

With the command generated to run within the task, and accessible URLs
generated for the genome tar and FastQ files, the following command
can be used to create the batch task.

```sh
az batch task create \
    --job-id <JOB_ID> \
    --task-id <TASK_ID> \
    --command-line "<COMMAND>" \
    --resource-files dragen.tar=<GENOME_URL> 1.fq.gz=<FQ1_URL> 2.fq.gz=<FQ2_URL>
```

#### Working Example

TODO: Fill in public genome url, fastq urls, and associated RGID and RGSM

```sh
az batch job create --id job1 pool-id mypool
```

`COMMAND=`

```bash
/bin/bash -c \
'mkdir dragen output; \
tar xzvf dragen.tar -C dragen; \
/opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true; \
/opt/edico/bin/dragen -f -r dragen \
    -1 1.fq.gz \
    -2 2.fq.gz \
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
    --lic-server <LICENSE>
```

```sh
az batch task create \
    --job-id job1 \
    --task-id task1 \
    --command-line "<COMMAND>" \
    --resource-files dragen.tar=<GENOME_URL> 1.fq.gz=<FQ1_URL> 2.fq.gz=<FQ2_URL>
```

#### Alternate File References

##### File Streaming

While it is always necessary to have the genome file locally on the node, DRAGEN
can stream the FastQ files for faster processing.

###### Stream From Public URL

* FQ1_URL: The full URL to the first public FastQ file.
* FQ2_URL: The full URL to the second public FastQ file.

`COMMAND=`

```bash
/bin/bash -c \
'mkdir dragen output; \
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
    --lic-server <LICENSE>
```

```sh
az batch task create \
    --job-id <JOB_ID> \
    --task-id <TASK_ID> \
    --command-line "<COMMAND>" \
    --resource-files dragen.tar=<GENOME_URL>
```

###### Stream from Azure Blob Storage

* STORAGE_ACCOUNT: The name of the blob storage account.
* STORAGE_ACCOUNT_KEY: An access key to the storage account.
* FQ1_URL: The full URL to the first FastQ file in Azure Blob Storage.
* FQ2_URL: The full URL to the second FastQ file in Azure Blob Storage.

`COMMAND=`

```bash
/bin/bash -c \
'echo DefaultEndpointsProtocol=https >> ~/.azure-credentials; \
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
    --lic-server <LICENSE>
```

```sh
az batch task create \
    --job-id <JOB_ID> \
    --task-id <TASK_ID> \
    --command-line "<COMMAND>" \
    --resource-files dragen.tar=<GENOME_URL>
```

##### FastQ List

If using a FastQ list file to reference and stream FastQ files, the Fast list file must
also be local to the node.  The below example shows an example of this using the
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
'echo DefaultEndpointsProtocol=https >> ~/.azure-credentials; \
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
    --lic-server <LICENSE>
```

```sh
az batch task create \
    --job-id <JOB_ID> \
    --task-id <TASK_ID> \
    --command-line "<COMMAND>" \
    --resource-files dragen.tar=$GENOME_URL fastq_list.csv=<LIST_URL>
```
