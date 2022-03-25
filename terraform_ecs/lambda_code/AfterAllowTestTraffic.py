import os
import boto3
import urllib3
from botocore.exceptions import ClientError

codedeploy = boto3.client('codedeploy')

def lambda_handler(event, context):

    load_balancer = os.environ['load_balancer']
    http = urllib3.PoolManager()
    url = "http://%s:88" % load_balancer
    resp = http.request('GET', url)
 
    print(load_balancer)

    try:
        if resp.status == 200:
            print('Website is alive !')
            print(event)
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=event["DeploymentId"],
                lifecycleEventHookExecutionId=event["LifecycleEventHookExecutionId"],
                status="Succeeded"
            )
        else:
            print('Website is broken !')
            print(event)
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=event["DeploymentId"],
                lifecycleEventHookExecutionId=event["LifecycleEventHookExecutionId"],
                status="FAILED"
            )
    except ClientError as e:
            print("Unexpected error: %s" % e)
            

