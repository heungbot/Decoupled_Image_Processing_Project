## Decoupled Image Processing Project

***

## 📄 프로젝트 설명
프로젝트 명 : 분리된 환경에서의 이미지 라벨링 자동화 프로젝트

프로젝트 인원 : 1명

프로젝트 기간 : 2023.08.28 ~ 2023.09

프로젝트 소개 : 본 프로젝트의 목표는 이미지 파일들을 S3 버킷에 업로드되었을 때, SNS + SQS를 이용하여 다른 작업과 분리된 프로세스로 이미지 라벨링 자동화를 구축하는 것입니다. 이를 위해 특정 S3 bucket에 이미지를 업로드하는 애플리케이션을 운영하는 상황과 요구사항을 가정하였습니다. 이에 따른 적합한 아키텍처를 설계하고, Terraform 모듈로 구성하는 프로젝트입니다.

***

## 📃 목차

[01. 클라이언트 상황 가정 ](#-01-클라이언트-상황-가정-)

[02. 요구사항 정의 ](#-02-요구사항-정의-)

[03. 다이어그램 ](#-03-다이어그램-)

[04. 핵심 서비스 소개 ](#-04-핵심-서비스-소개-)

[05. 구현 과정 ](#-05-구현-과정-)

[06. 테스트 및 결과 ](#-06-테스트-및-결과-)

***

## [ 01 클라이언트 상황 가정 ]

* AWS Service를 활용하여 웹사이트를 운영중

* 자정에 유저로 부터 받은 이미지 파일들을 s3 bucket에 저장하는 웹 서비스

* 추후 서비스에 다른 기능 추가 예정. 이미지 형식 및 사이즈에 따라 다른 다양한 작업 수행할 계획

***

## [ 02 요구사항 정의 ]

* 추가될 다른 기능들과 이미지 라벨링 작업을 분리할 수 있는 환경 요망

* 라벨링 작업과 관련된 서비스들은 관련 서비스들만 접근할 수 있도록 보안조치 요망

* CloudWatch를 이용한 모니터링 및 알람 설정

* 라벨링 작업의 실패하여 Dead Letter Queue에 특정 이상의 메시지가 쌓이면 Slack Channe에 공지 요망.

***

## [ 03 다이어그램 ]

<img width="1234" alt="Image_Processing_Arch_Real" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/9aeef487-fd1d-4639-9ada-762ffb65baed">

### 동작 과정
1. 특정 S3 bucket, Prefix에 Image 업로드

2. S3 event notification을 통해 SNS Topic으로 메시지 publish

3. Topic을 구독중인 SQS가 Subscription Filter policy에 맞게 메시지 소비

4. SQS에 들어간 메시지는 Lambda가 Rekognition API호출하여 Labeling 작업 후, Result Bucket에 업로드.

   4-1. SQS에 들어간 메시지가 소비되지 않았을 경우, Dead Letter Queue로 전달

   4-2. Dead Letter Queue에 대한 Cloud Watch Alarm이 SNS Topic으로 Publish.

   4-3. Cloudwatch에서 온 알람을 Filter Policy를 거쳐 구독중인 Lambda에게 도달하고 활성화 되어 Slack으로 알람 공지

   4-4. Slack 알람을 확인 후, Dead Letter Queue에 전달된 메시지를 관련팀이 디버깅

***

## [ 04 핵심 서비스 소개 ]

<img width="1204" alt="SNS" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/ba158893-83b2-4a5c-97a7-58623c6d048a">

### 1. SNS : AWS에서 손쉽게 알람을 설정, 운영 및 전송할 수 있는 서비스.
* 특정 Topic에 대해 Publisher가 Message를 게시하고, Topic을 구독하고 있는 Subscriber가 Message를 수신하는 방식(Pub/Sub)

* S3, CloudWatch 등 많은 AWS Service들이 sns로 알림을 보낼 수 있음

* Resource Based Policy를 통해 message를 publish할 서비스에 대해 제어가 가능

* Subscription FIlter Policy를 통해 구독에게 보낼 메시지 제어 가능.
    -> 메시지 속성 or 메시지 본문에 대한 필터 적용

* 하나의 Topic에 대해 12,500,000개의 구독 가능(Standard Type기준)

* Standard Type과 FIFO Type이 존재함.

|Feature|Standard|FIFO|
|:---:|:---:|:---:|
|처리량|초당 거의 무한에 가까운 메시지 처리 가능|초당 300개의 메시지 or 10MB|
|메시지 순서|메시지 게시 순서와 동일하지 않음|선입선출(First In First Out)|
|구독자|SQS, Kinesis Firehose, HTTPS, Lambda, SMS, Email, Mobile push|FIFO SQS|
|메시지 전달 횟수|한 번 이상 전달(메시지 중복 가능)|한 번|

*** 

<img width="1190" alt="SQS" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/b56a6702-919a-4127-bd68-79a7dcbd0077">


### 2. SQS : 분산 시스템 및 서버리스 어플리케이션 분리, 확장을 위한 완전 관리형 메시지 대기열 서비스

* 보기 제한 시간(Visibility Timeout) : 서비스가 SQS의 Message를 받은 뒤, 특정 시간 동안 다른 서비스가 동일 메시지를 처리하지 않도록 설정하는 기능

* 처리 실패 큐(Dead Letter Queue) : SQS에서 어떤 메시지가 설정 횟수를 초과하여 삭제되지 않았을 경우 보내지는 SQS

* Long Polling : SQS에 메시지가 없을 경우, Consumer가 메시지를 "대기"하는 것(1~20초)
이는 API 호출 횟수를 줄일 수 있으며, latency 감소
queue level 및 WaitTimeSeconds API를 통해 활성화 가능

* 어플리케이션이 SendMessage API를 사용하여 SQS에 메시지를 전송함.

* SQS에 적재된 메시지를 다른 서비스(Servers, EC2, Lambda..)등이 polling 하여 메시지를 처리 후 메시지 삭제(DeleteMessage API)

* Standard Type과 FIFO Type이 존재함

|Feature|Standard|FIFO|
|:---:|:---:|:---:|
|처리량|거의 무한에 가까운 메시지 처리 가능|초당 300개의 트랜잭션(batch 처리 시, 3000) |
|메시지 순서|Best Effort Ordering(순서가 맞지 않을 수 있음)|선입선출(First In First Out)|
|지원 AWS 서비스|모든 서비스|일부 서비스 제외한 모든 서비스|
|메시지 전달 횟수|한 번 이상 전달(메시지 중복 가능)|한 번|

***

<img width="1197" alt="Lambda_and_Rekognition" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/b7374202-d138-4bc9-8dfe-8381f83df83f">

### 3. Lambda : 서버를 프로비저닝하거나 관리할 필요 없이 코드를 실행할 수 있는 서버리스 컴퓨팅 서비스.

* 프로그램 zip파일을 lambda console에서 업로드 하거나, s3에서 업로드 가능(50Mb 초과할 경우, S3에서 업로드)

* AWS Service와 통합 가능하며 여러 프로그래밍 언어를 지원

* AWS Service에서 특정 이벤트를 트리거 삼아 호출할 수 있으며, eventbridge와 통합하여 Cronjob 형태로 호출이 가능

* 밀리초 단위로 코드가 실행되는 시간 및 코드가 트리거 되는 횟수를 기준으로 요금이 부과. 즉, 사용한 만큼 지불하는 형식

* 메모리 크기 및 tmp 스토리지 사이즈, 람다 실행 제한 시간 등을 설정.

* lambda가 기본적으로 지원하지 않는 library를 사용하는 경우, package를 함께 업로드 하거나, lambda layer를 사용.

### 4. Rekognition : 어플리케이션에서 이미지 및 비디오 분석을 쉽게 추가할 수 있도록 하는 AWS에서 제공하는 인공 지능 서비스.
* Console에서 이미지 업로드 하거나, API를 호출하는 방식으로 사용
* 물체/장면 감지, 얼굴 분석 및 비교, 안면 인식 등의 기능 보유.

***

## [ 05 구현 과정 ]

### 1. S3 Bucket

<img width="1015" alt="스크린샷 2023-09-01 오후 4 30 23" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/86ae7f8c-111f-48e4-9954-1f553c69d8fe">
* 이미지가 들어올 "ingest" 폴더와 결과가 저장될 "reuslts" 폴더 생성

<img width="1326" alt="스크린샷 2023-09-01 오후 4 31 12" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/6453ac2f-262f-478e-97e9-0b82407ba72c">
* SNS로 Event를 Push하기 위해 이벤트 알림 설정

***

### 2. SNS

<img width="834" alt="스크린샷 2023-09-01 오후 4 31 53" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/9dbcf85a-2c83-43d7-b21d-12b0c9ae115c">

* User와의 즉각적인 상호작용이 아닌, 업로드된 이미지에 라벨링 작업이므로 FIFO 보단 Standard 적용
* SNS Topic에 대한 Resource Based Policy는 아래와 같이 설정함

```
<SNS_TOPIC_POLICY>
{
  "Version": "2012-10-17",
  "Id": "AllowS3Publish",
  "Statement": [
    {
      "Sid": "AllowS3Publish",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": [
        "sns:Subscribe",
        "sns:Publish"
      ],
      "Resource": "[SNS TOPIC ARN]",
      "Condition": {
        "ArnEquals": {
          "AWS:SourceArn": [BUCKET ARN]"
        }
      }
    },
    {
      "Sid": "AllowCloudWatchPublish",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": [
        "sns:Subscribe",
        "sns:Publish"
      ],
      "Resource": "[TOPIC ARN]"
    }
  ]
}
```
* S3 Bucket과 CloudWatch의 알람의 메시지 푸시만 허용하는 정책

***

### 3. SQS

<img width="1255" alt="스크린샷 2023-09-01 오후 4 35 17" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/3240a48c-0bab-4732-9484-cebcea1ebbb8">

* 라벨링 작업을 위한 MAIN Queue와 Dead Letter를 위한 Dead Letter Queue 생성
* 상세 구성은 아래와 같음

<img width="1182" alt="스크린샷 2023-09-01 오후 4 36 13" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/5ba0677a-c38b-4551-851f-95cfc08844a9">

* Main Queue의 Resource Based Policy는, SNS의 Topic에서의 Message Push만 허용해야 하므로 정책은 아래와 같음.

```
{
  "Version": "2012-10-17",
  "Id": "AllowPublishMessageFromSNS",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "[MAIN_QUEUE_ARN]",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "TOPIC_ARN"
        }
      }
    }
  ]
}
```

* Dead Letter Queue의 Resource Based Policy는 Main Queue의 접근에 대한 권한이 필요하며 아래와 같이 설정함. 

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "sqs:StartMessageMoveTask",
        "sqs:ReceiveMessage",
        "sqs:ListMessageMoveTasks",
        "sqs:GetQueueAttributes",
        "sqs:DeleteMessage",
        "sqs:CancelMessageMoveTask,
	 sqs:SendMessage"
      ],
      "Resource": "[DLQ_ARN]",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "[MAIN_QUEUE_ARN]"
        }
      }
    }
}
```
* 생성이 완료 되었다면, SQS에 대한 CldouWatch Alarm 설정

<img width="1088" alt="스크린샷 2023-09-01 오후 4 52 32" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/f65ad425-b347-4dba-9075-b89846c33164">

* Metric에 대한 조건은 상황에 맞게 설정 가능

***

### 4. Lambda

<img width="864" alt="스크린샷 2023-09-01 오후 4 45 45" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/88807400-5fa2-4f27-beed-88f4066c53ab">

* 이미지 처리를 위한 Lambda.
* SQS의 Message를 Trigger로 설정
* Lambda function 내부에서 Rekognition API중 하나인 "detect_labels" 호출

<img width="794" alt="스크린샷 2023-09-01 오후 4 46 58" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/e26a800b-609b-4971-ab2e-cded84cb75a8">

* 비교적 무거운 작업을 진행하는 람다이기 때문에 메모리와 제한시간을 기본값 보다 높게 설정


<img width="860" alt="스크린샷 2023-09-01 오후 4 48 17" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/82e7673a-53a1-44b9-ae7f-0b65ce7b0a88">

* Dead Letter Queue에 임계값 이상의 Message가 쌓였을 경우, Slack 알람 발송을 위한 람다.
* Lambda 테스트 시, 제한 시간 기본값인 3초 보다 더 소요되기 때문에 10초로 설정

***

## [ 06 테스트 및 결과 ]

### 6.1 Rekognition Lambda TEST

<img width="327" alt="스크린샷 2023-09-01 오후 9 41 53" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/03e6993b-9d6f-4608-819f-59d92ccabad7">

* 길거리에 사람이 존재하는 위 사진을 테스트 파일 "heungbot.jpg" 로 명명하고 이를 "ingest/" 폴더에 업로드

<img width="1384" alt="lambda_results" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/ed3e4528-7dc7-42b6-b28f-b8503d5a46c2">

* "results/" 폴더에 Rekognition API의 결괏값이 S3 - SNS - SQS - Lambda를 거쳐 json 파일로 업로드.
* API의 결과는 아래와 같음. 사진의 구성에 대한 Labeling을 성공적으로 수행하는 모습

```
{
  "Labels":[
     {
        "Name":"City",
        "Confidence":99.99974060058594,
        "Instances":[
           
        ],
        "Parents":[
           
        ],
        "Aliases":[
           {
              "Name":"Town"
           }
        ],
        "Categories":[
           {
              "Name":"Buildings and Architecture"
           }
        ]
     },
     {
        "Name":"Road",
        "Confidence":99.99974060058594,
        "Instances":[
           
        ],
        "Parents":[
           
        ],
        "Aliases":[
           
        ],
        "Categories":[
           {
              "Name":"Transport and Logistics"
           }
        ]
     },
     {
        "Name":"Street",
        "Confidence":99.99974060058594,
        "Instances":[
           
        ],
        "Parents":[
           {
              "Name":"City"
           },
           {
              "Name":"Road"
           },
           {
              "Name":"Urban"
           }
        ],
        "Aliases":[
           
        ],
        "Categories":[
           {
              "Name":"Buildings and Architecture"
           }
        ]
     },
     {
        "Name":"Photography",
        "Confidence":99.9996337890625,
        "Instances":[
           
        ],
        "Parents":[
           
        ],
        "Aliases":[
           {
              "Name":"Photo"
           }
        ],
        "Categories":[
           {
              "Name":"Hobbies and Interests"
           }
        ]
     },
     {
        "Name":"Person",
        "Confidence":99.99934387207031,
        "Instances":[
           {
              "BoundingBox":{
                 "Width":0.6735371351242065,
                 "Height":1.0,
                 "Left":0.00011039733362849802,
                 "Top":0.0
              },
              "Confidence":99.4738998413086
           }
        ],
        "Parents":[
           
        ],
        "Aliases":[
           {
              "Name":"Human"
           }
        ],
        "Categories":[
           {
              "Name":"Person Description"
           }
        ]
     },
     {
        "Name":"Portrait",
        "Confidence":99.99934387207031,
        "Instances":[
           
        ],
        "Parents":[
           {
              "Name":"Face"
           },
           {
              "Name":"Head"
           },
           {
              "Name":"Person"
           },
           {
              "Name":"Photography"
           }
        ],
        "Aliases":[
           
        ],
        "Categories":[
           {
              "Name":"Hobbies and Interests"
           }
        ]
     },
     {
        "Name":"T-Shirt",
        "Confidence":99.9935302734375,
        "Instances":[
           
        ],
        "Parents":[
           {
              "Name":"Clothing"
           }
        ],
        "Aliases":[
           
        ],
        "Categories":[
           {
              "Name":"Apparel and Accessories"
           }
        ]
     },
     {
        "Name":"Path",
        "Confidence":99.96382904052734,
        "Instances":[
           
        ],
        "Parents":[
           
        ],
        "Aliases":[
           
        ],
        "Categories":[
           {
              "Name":"Nature and Outdoors"
           }
        ]
     },
     {
        "Name":"Sidewalk",
        "Confidence":99.77108001708984,
        "Instances":[
           
        ],
        "Parents":[
           {
              "Name":"Path"
           }
        ],
        "Aliases":[
           {
              "Name":"Pavement"
           }
        ],
        "Categories":[
           {
              "Name":"Buildings and Architecture"
           }
        ]
     },
     {
        "Name":"Tarmac",
        "Confidence":99.61927795410156,
        "Instances":[
           
        ],
        "Parents":[
           {
              "Name":"Road"
           }
        ],
        "Aliases":[
           {
              "Name":"Asphalt"
           }
        ],
        "Categories":[
           {
              "Name":"Transport and Logistics"
           }
        ]
     }
  ],
  "LabelModelVersion":"3.0",
  "ResponseMetadata":{
     "RequestId":"5eaba5a4-779d-48fd-a136-71b9539b17d9",
     "HTTPStatusCode":200,
     "HTTPHeaders":{
        "x-amzn-requestid":"5eaba5a4-779d-48fd-a136-71b9539b17d9",
        "content-type":"application/x-amz-json-1.1",
        "content-length":"1815",
        "date":"Fri, 01 Sep 2023 07:15:11 GMT"
     },
     "RetryAttempts":0
  }
}
```
  
<img width="1047" alt="스크린샷 2023-09-01 오후 9 35 25" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/d6731dbb-07cf-4024-b965-1be5e61cd4fb">

* 30초 간의 polling 시도 시, Lambda의 "DeleteMessage API" 호출을 통해  메시지가 삭제됨을 확인

***

### 6.2 Slack Lambda Test

<img width="851" alt="스크린샷 2023-09-01 오후 10 38 00" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/a59b5782-2d69-4686-b0e2-1e10c4bf94ff">

* 알람 테스트를 위해 Dead Letter Queue 알람의 임계값 수정
* 1분 동안 임계값을 넘은 경우가 2번이상 발생할 경우 Cloudwatch Alarm 활성화

<img width="1023" alt="스크린샷 2023-09-01 오후 10 40 51" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/1cfbe1ed-4dee-4d6b-8db8-9d776bbd996f">

* Dead Letter Queue 콘솔에서 테스트 메시지 3개를 전송.

<img width="935" alt="스크린샷 2023-09-01 오후 10 41 41" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/6799dcf8-64e7-49b8-92b1-452e9c47057c">

* 메시지가 queue에서 사라지지 않는 것을 cloudwatch가 알아 채고 UTC로13시 26분, 한국 시각(UTC + 9)으로 오후 22시 26분에 알람 활성화

<img width="886" alt="스크린샷 2023-09-01 오후 10 43 43" src="https://github.com/heungbot/Image_Processing_Project/assets/97264115/cf437cc1-89ab-4366-abf1-0cfd5107aa12">

* Cloudwatch Alarm - SNS를 거쳐 Lambda가 활성화 됨
* 동일 시간에 Slack 알람이 온 것을 확인


