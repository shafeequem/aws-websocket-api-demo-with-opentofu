import json
import boto3
import os

dynamodb = boto3.client('dynamodb')
table = os.environ['table']

def lambda_handler(event, context):
    print(event)
    print("****")
    print(context)
    # TODO implement
    dynamodb.put_item(TableName=table, Item={'ConnectionID':{'S':event['requestContext']['connectionId']},'UserID':{'N':event['UserID']}})
    return {
        'statusCode': 200
    }
    

    