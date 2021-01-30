# AWS API키 설정 #

본 워크샵에서는 테라폼을 이용하여 AWS 클라우드상에 테스트용 인프라 스트럭처를 배포합니다. 
테라폼은 HCL기반으로 리소스를 선언 및 관리하는 오픈소스 IaC 도구로서, AWS 에 인프라를 배포하기 위해서는 AWS 계정이 반드시 필요합니다.
테라폼이 AWS 의 API 를 호출하기 위해서는 API키 설정이 필요한 데, 해당 키는 다음과 같은 방법으로 여러분들의 로컬 PC에 설정하실 수 있습니다.

## AWS CLI 를 통한 설정 ##

아래의 명령어를 이용하여 최신버전의 aws cli 를 다운로드 받아서 로컬 PC에 설치합니다. 이때 로컬 PC 계정의 어드민 패스워드를 입력해야 합니다. 
```
$ curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

$ sudo installer -pkg ./AWSCLIV2.pkg -target /
Password:
installer: Package name is AWS Command Line Interface
installer: Upgrading at base path /
installer: The upgrade was successful.

$ aws --version
aws-cli/1.18.130 Python/3.8.0 Darwin/19.6.0 botocore/1.17.53
```

AWS 로 로그인 하여 API 호출을 위한 KEY 와 SECRITE 키 정보를 확인한 후 아래와 같이 해당 키값을 설정합니다. 



## 환경변수를 이용한 설정 ##

