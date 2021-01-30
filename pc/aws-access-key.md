# AWS 억세스 키 설정 #

본 워크샵에서는 테라폼을 이용하여 AWS 클라우드에 인프라 스트럭처를 배포합니다.   
테라폼은 HCL 기반으로 리소스를 선언 및 관리하는 오픈소스 IaC 도구로서, AWS 클라우드에 인프라를 배포하기 위해서는 AWS 계정이 반드시 필요합니다.  
테라폼이 AWS 의 API 를 호출하기 위해서는 API Acesss 키 설정이 필요한 데, 테라폼은 aws cli 의 설정키, 또는 환경변수 그리고 자체적인 Access Key 설정값으로 부터 관련 정보를 참조 합니다.
이번 워크샵에서는 환경변수를 이용하여 테라폼에게 억세스 키 값을 전달하도록 하겠습니다. 

## 환경변수를 통한 전달 ##

아래와 같이 bash profile 에 억세스 키 정보를 추가하도록 합니다. 엑세스 키 정보는 AWS IAM 콘솔의 Users 메뉴의 유저별 Security Credentials 탭에서 확인 가능합니다.
만약 해당 유저의 억세스키 값이 발급되어 있지 않다면 아래의 URL 을 참고하여 억세스키를 먼저 발급 하십시오

* [억세스 키 생성하기](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)

```
$ cd
$ vi .bash_profile

export aws_access_key_id = AAaaaaaaaaaaaaa                          <--- 억세스키 추가
export aws_secret_access_key = SSssssssssssssss                     <--- 시크리트 억세스키 추가 
export aws_region = "ap-northeast-2"                                <--- 리전 설정
```
