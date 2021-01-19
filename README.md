# postgres-terraform

이 튜토리얼은 Mac OS 기준으로 작성되었다. 클라이언트가 윈도우인 경우, 구글 검색을 통해 관련된 명령어를 찾아야 한다.   
실습용 인프라는 테라폼을 이용하여 빌드하는데, 테라폼 관련 정보는 다음 URL 을 통해 확인할 수 있다. (https://www.terraform.io/)  
이번 튜토리얼에서는 테라폼에 대한 내용은 다루지 않는다. 

## 실습 아키텍처 ##

### 1. 소프트웨어설치 ###
  * 테라폼
  * Git
  * Pgadmin4
  * SQLDeveloper


### 2. 테라폼 프로젝트를 로컬 PC로 다운받기 ###

로컬 PC 로 terraform 코드를 clone 한다. 

```
$ cd                      # home 디렉토리로 이동
$ git clone https://github.com/gnosia93/postgres-terraform.git
$ cd postgres-terraform/
```

### 3. AWS 로그인키 설정 ####
```
$ aws configure           # region 과 aws key 설정
```

### 4. 인프라 빌드 ###
```
$ terraform apply -auto-approve
```

### 5. 오라클 설정 ###

DMS을 이용하여 CDC 방식으로 데이터를 복제하기 위해서는 아래의 두가지 요건을 충족해야 한다.

* 아카이브 로그 모드 활성화
* supplemental 모드 활성화

### 6. 오라클 데이터 로딩 ###

데이터 로딩은 자동으로 빌드된 ec2 인스턴스 중, tf_loggen 이라는 이름을 가지 인스턴스로 로그인 한 후, 아래의 명령어를 이용하여 진행하면 된다.
스키마 생성 및 초기 데이터 로딩의 대상이 되는 오라클 데이터베이스의 IP 는, 자동으로 설정되기 때문에 아래의 명령어를 수행하기만 하면 된다. 

```

```

### 7. postgres 설정 ###


### 8. DMS 태스크 설정 ###


### 9. DMS 모니터링 ###












