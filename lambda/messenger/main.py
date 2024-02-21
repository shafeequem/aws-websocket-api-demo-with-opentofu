import json
import boto3 
from boto3.dynamodb.conditions import Attr
import os

api_client = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['api_endpoint_url'])
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['table'])

def lambda_handler(event, context):
    
    #Extract connectionId and desired message to send from input
    user = event["user"]
    message = event["message"]
    
    response = table.scan(
        FilterExpression=Attr('User').eq(user)
    )
    items = response['Items']

    for item in items:
        api_client.post_to_connection(ConnectionId=item['ConnectionID'], Data=json.dumps(message).encode('utf-8'))
        print (item)