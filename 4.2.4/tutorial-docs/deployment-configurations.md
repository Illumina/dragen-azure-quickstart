### Advanced Usage: ARM Template

Incorporating DRAGEN on Azure into an existing solution may be as easy as using the [ARM template](mainTemplate.json) that is exported alongside this documentation.

#### Usage Scenarios

Deployment using the ARM template enables several more advanced scenarios, such as:

* Incorporation of infrastructure components needed for DRAGEN into an existing infrastructure
* Automated deployments via CI/CD pipelines
* Customization of the deployment to meet your needs

#### Prerequisites for ARM Template Deployment

Before attempting to deploy to your subscription via the ARM template, ensure that you have completed all of the [prerequisites](#prerequisites) for running DRAGEN on Azure.

#### Parameters

The ARM template takes the following input parameters:

##### Required parameters (no default value set)

| Parameter Name | Description |
| -------------- | ----------- |
| `prefix` | Prefix for resource names (1-17 alphanumeric characters) |
| `azureBatchServiceOid` | Object ID for Azure Batch on the user's tenant (Can be found by running the command `az ad sp show --id ddbf3205-c6bd-46ae-8127-60eb93363864 --query objectId`) |

##### Optional parameters (default values are set but can be overridden)

| Parameter Name | Default Value | Description |
| -------------- | ------------- | ----------- |
| `location` | Resource group location | Azure Region where resources should be deployed |
| `storageAccountName` | `prefix` + "storage" | Name for Azure Blob Storage account (Total of 3-24 alphanumeric characters including prefix) |
| `storageSku` | Standard_LRS* | [Azure Storage SKU](https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types) |
| `storageNewOrExisting` | new | Specify whether to use an existing storage account or create a new one (Allowed values: `new` or `existing`) |
| `offerSku` | dragen-4-0 | SKU for the DRAGEN offer in the Marketplace |
| `vmImageVersion` | 4.0.3 | DRAGEN version |

***NOTE:** The "Premium" type SKUs are not currently supported by this offering.

#### Sample ARM Template Deployment

The following sample deploys the ARM template into a resource group using the Azure CLI [deployment group create](https://docs.microsoft.com/en-us/cli/azure/deployment/group?view=azure-cli-latest#az_deployment_group_create) command:

```sh
# Set variables for command inputs
RESOURCE_GROUP_NAME="dragen-rg"
LOCATION="EastUS"
PREFIX="dragen"
BATCH_OID=<Batch Object Id for your tenant - see Parameters section>

# Create a resource group
az group create -n "$RESOURCE_GROUP_NAME" -l "$LOCATION"

# Deploy the ARM template
az deployment group create \
    -g "$RESOURCE_GROUP_NAME" \
    -p prefix="$PREFIX" \
    -p azureBatchServiceOid="$BATCH_OID" \
    -f mainTemplate.json \
    --query "properties.outputs"
```

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
