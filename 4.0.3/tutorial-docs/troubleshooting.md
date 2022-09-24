### ARM Deployment

If you are running into issues getting the infrastructure spun up through the
ARM template, there are a few options for debugging:

1. If the resource group was created, navigate to the resource group, and
then the deployments menu option.  Here you will find the list of deployments
tied to this resource group, and navigating deeper into each deployment
may show additional information for the deployment of each resource.

2. Open the [Activity Log](https://ms.portal.azure.com/#blade/Microsoft_Azure_ActivityLog/ActivityLogBlade)
for an additional source of information for recent issues within your subscription.

### Batch Tasks

If you are running into issues getting your batch task to run successfully,
the best place to get information to help debug the problem is within the
`stdout` and `stderr` of the batch task itself.  This can be accessed by navigating
to your batch account in the portal, and then to the specific job and task
that ran.  Once there, you will be able to access `stdout.txt` and `stderr.txt`:

![batch-task-file-list](./images/batch-task-file-list.png)

### DRAGEN Issues

For failed DRAGEN runs, navigate to the batch account in the portal, then job and task associated with the failed run
to view DRAGEN log files.

### Common Issues

1. Quota issues:  If quota increases haven't been requested, it can be common
to run into quota issues for both the number of batch accounts as well as for
the `Standard NPS Family vCPUs`.  Please make sure you have available
[quota](#deployment-steps) before deploying the ARM template.

2. Input file streaming:  Currently, DRAGEN does not support input streaming
from public Blob containers.  Input files from private Blob containers can be
streamed provided that the proper storage credentials are passed to the batch
command.

3. Command lines: Ensure that variables supplied to Azure CLI commands (e.g., account keys, license URLs, names of
resource groups, batch accounts, storage accounts and containers, batch pools, etc.) are correct.  Ensure that DRAGEN
command lines are formed properly and that the correct variables are passed to it.

4. Task JSON:  Ensure that keys and values supplied to the json task file are correct and complete.  Ensure that the
file adheres to JSON formatting rules.

5. Authentication:  Ensure that the Azure CLI is authenticated for use with the proper subscription prior to creating
resource groups and deploying ARM templates.  Log in to the proper Azure batch account prior to creating
batch jobs and tasks.  Provide the required authentication (e.g., SAS tokens) for private storage accounts and/or
input files, as needed.  Ensure that sufficient expiration periods are specified when generating authentication tokens.
