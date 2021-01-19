# postgres-terraform

이 튜토리얼은 Mac OS 기준으로 작성되었다. 클라이언트 PC 로 윈도우를 사용하는 경우, 구글 검색을 통해 관련된 명령어를 찾아야 한다.

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


### 6. 오라클 데이터 로딩 ###


### 7. postgres 설정 ###


### 8. DMS 태스크 설정 ###


### 9. DMS 모니터링 ###












