## Deployment - Additional Configurations

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
