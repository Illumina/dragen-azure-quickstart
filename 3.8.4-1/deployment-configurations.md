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

Deployment using the ARM template enables several more advanced scenarios, such as:

* Incorporation of infrastructure components needed for DRAGEN into an existing infrastructure
* Automated deployments via CI/CD pipelines
* Customization of the deployment to meet your needs

#### Using a New vs. Existing Storage Account

By default, the ARM template included with this quickstart creates a new storage account and container.  Some users may already have data uploaded to an existing Azure Blob Storage account.  To use existing storage, specify the following input parameters to the ARM template in your deployment:

* `storageNewOrExisting: existing`
* `storageAccountName: <name of your existing storage account>`

### Batch Job & Task Timeout

It is possible to set a max run time on either the batch job or batch task.

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

If you would like to set a max run time on the batch task instead, you can add
the following section to the task.json:

```json
"constraints": {
    "maxWallClockTime": "PT360M"
}
```

### Other Deployment Considerations

After deploying DRAGEN on Azure, users will want to take into account the following additional deployment considerations and options, which are *not* included as part of this quickstart template:

* Compliance
* Authentication
* Security
* Monitoring and Observability

Decisions regarding implementation of any of the above are left to the end user's discretion.
