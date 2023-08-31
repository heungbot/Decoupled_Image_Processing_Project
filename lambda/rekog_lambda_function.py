import os
import boto3
import json

s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')
sqs = boto3.client('sqs')

def lambda_handler(event, context):
    for record in event['Records']: # 
        
        sns_message = json.loads(record['body'])['Message']
        print("SNS_MESSAGE :", sns_message)
        
        message_dict = json.loads(sns_message)
        bucket = message_dict['Records'][0]['s3']['bucket']['name']
        key = message_dict['Records'][0]['s3']['object']['key']

        
        print("BUCKET NAME :",bucket)
        print("OBJECT KEY :", key) 
        
        # rekognition api 호출
        labels = rekognition.detect_labels( # event에서 key에 대한 정보 빼와서 rekognition api 적용도 가능
            Image = {
                # 'Bytes': bytes, 
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key,
                    # 'Version': '' # bucket versioning이 enabled 일 때, 객체의 버전을 설정할 수 있음
                }
            },
            MaxLabels=10
        )
        
        # 결과값 확인
        print("Detected labels:", labels)
        result_file = json.dumps(labels)
        
        file_name, _ = os.path.splitext(key)
        result_file_name = file_name.split("/")[-1] + ".json"
        
        # 결과 업로드
        resp = s3.put_object(
            Bucket = bucket,
            Key = "results/" + result_file_name,
            Body = result_file,
            ContentType = "application/json"
        )
        print("Result Uploaded in S3 Result Prefix")
        
        # 처리한 sqs message 삭제
        resp = sqs.delete_message(
            QueueUrl = os.environ['SQS_URL'],
            ReceiptHandle = record['receiptHandle']
        )
        print("Handled SQS Message Deleted")
        
        
# s3 bucket - sns - sqs - lambda
# sns_message = event['Records']['body'] # sqs는 벗김. 이는 sns message.
# bucket_name = sns_message['Records'][0]['s3']['bucket']['name']
# key = sns_message['Records'][0]['s3']['object']['key']
