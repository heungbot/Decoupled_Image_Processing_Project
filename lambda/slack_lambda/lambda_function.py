import json
import logging
import os
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Slack 웹훅 URL
HOOK_URL = os.environ['hookUrl']
SLACK_CHANNEL = os.environ['slackChannel']

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Event: " + json.dumps(event))
    
    # SNS 메시지 문자열 가져오기
    sns_message = event['Records'][0]['Sns']['Message']
    # logger.info("SNS Message: " + sns_message)
    print(sns_message['AlarmName'])
    
    alarm_name = sns_message["AlarmName"]
    threshold = sns_message["Trigger"]["Threshold"]
    print(alarm_name, threshold)

    # Slack 메시지 구성
    slack_message = {
        'channel': SLACK_CHANNEL,
        'text': "%s!! : Number of DLQ message over threshold (%f)" % (alarm_name, threshold)
    }

    req = Request(HOOK_URL, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)


# # test event
# {
#   "Records": [
#     {
#       "EventSource": "aws:sns",
#       "EventVersion": "1.0",
#       "EventSubscriptionArn": "arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#       "Sns": {
#         "Type": "Notification",
#         "MessageId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#         "TopicArn": "arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms",
#         "Subject": "ALARM: \"Example alarm name\" in EU - Ireland",
#         "Message": {
#           "AlarmName": "heungbot-image-processing-queue-not-empty-alarm",
#           "AlarmDescription": "Example alarm description.",
#           "AWSAccountId": "000000000000",
#           "NewStateValue": "ALARM",
#           "NewStateReason": "Threshold Crossed: 1 datapoint (10.0) was greater than or equal to the threshold (1.0).",
#           "StateChangeTime": "2017-01-12T16:30:42.236+0000",
#           "Region": "EU - Ireland",
#           "OldStateValue": "OK",
#           "Trigger": {
#             "MetricName": "DeliveryErrors",
#             "Namespace": "ExampleNamespace",
#             "Statistic": "SUM",
#             "Unit": null,
#             "Dimensions": [],
#             "Period": 300,
#             "EvaluationPeriods": 1,
#             "ComparisonOperator": "GreaterThanOrEqualToThreshold",
#             "Threshold": 1
#           }
#         },
#         "Timestamp": "2017-01-12T16:30:42.318Z",
#         "SignatureVersion": "1",
#         "Signature": "Cg==",
#         "SigningCertUrl": "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.pem",
#         "UnsubscribeUrl": "https://sns.eu-west-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#         "MessageAttributes": {}
#       }
#     }
#   ]
# }