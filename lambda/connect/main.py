import json

def lambda_handler(event, context):
    print(event)
    print("****")
    print(context)
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
    