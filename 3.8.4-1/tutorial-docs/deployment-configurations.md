### Using a New vs. Existing Storage Account

By default, the template deployed through this quickstart creates a new storage account and container.  If you already have data uploaded to an existing Azure Blob Storage account, it is possible to specify this as part of the deployment.

Using the portal UI, in the "Storage Settings" tab, under the dropdown for "Storage account" simply select the name of your existing storage account.

If deploying the ARM template manually via some other means, include the following in your input parameters to the template:

* `storageNewOrExisting: existing`
* `storageAccountName: <name of your existing storage account>`

### Batch Job & Task Timeout

It is possible to set a max run time on either the batch job or batch task.

[Batch job set CLI reference](https://docs.microsoft.com/en-us/cli/azure/batch/job?view=azure-cli-latest#az_batch_job_set)

The below command will terminate the batch job as well as all tasks within
it after the job has been present for 360 minutes.

* JOB_ID: The job id of the already created job.
* PT360M: An ISO-8601 duration, PT360M = 360 minutes.

```sh
az batch job set \
    --job-id $JOB_ID \
    --on-all-tasks-complete "terminatejob" \
    --job-max-wall-clock-time "PT360M"
```

[Task constraints CLI reference](https://docs.microsoft.com/en-us/rest/api/batchservice/task/add#taskconstraints)

If you would like to set a max run time on the batch task instead, you can add
the following section to the task.json:

```json
"constraints": {
    "maxWallClockTime": "PT360M"
}
```

### Advanced Usage: ARM Template

Incorporating DRAGEN on Azure into an existing solution may be as easy as using the [ARM template](https://github.com/Illumina/dragen-azure-quickstart/blob/gh-pages/{{site.dragen_version}}/mainTemplate.json) that is exported alongside this documentation.

Download the [template](https://github.com/Illumina/dragen-azure-quickstart/blob/gh-pages/{{site.dragen_version}}/mainTemplate.json) and run the following commands to deploy.

```sh
RESOURCE_GROUP="dragen"

az group create -n "$RESOURCE_GROUP" -l "EastUS"

az deployment group create \
    -g "$RESOURCE_GROUP" \
    -p prefix=fpgaci \
    -p azureBatchServiceOid=795cc567-16b1-4904-9344-afc876387199 \
    -f mainTemplate.json \
    --query "properties.outputs"
```

### Other Deployment Considerations

After deploying DRAGEN on Azure, users will want to take into account the following additional deployment considerations and options, which are *not* included as part of this quickstart template:

* Compliance
* Authentication
* Security
* Monitoring and Observability

Decisions regarding implementation of any of the above are left to the end user's discretion.
