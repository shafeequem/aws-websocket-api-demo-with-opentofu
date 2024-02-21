import json
import boto3
import os

dynamodb = boto3.client('dynamodb')
table = os.environ['table']
userid = '1233'

def lambda_handler(event, context):
    print(event)
    print("****")
    print(context)
    # TODO implement
    dynamodb.delete_item(TableName=table, Key={'ConnectionID':{'S':event['requestContext']['connectionId']}})
    return {
        'statusCode': 200
    }
    

    