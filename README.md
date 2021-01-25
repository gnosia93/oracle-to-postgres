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

인프라 구성요소는 소스 데이터베이스인 오라클과 타켓 데이터베이스인 postgresql, 데이터 복제시 사용할 DMS 인스턴스 및 초기 데이터 로딩에 사용되는 EC2 인스턴스로 구성되어 있다.  
오라클 설치, OS 파리미터 설정, 네트워크 설정 등과 같은 기본적인 설정은 모두 자동화 되어 있기 때문에, DMS 와 postgresql 에 대한 이해도를 높일 수...

```
var.tf 수정 (내아이피 확인후)
$ terraform apply -auto-approve
```

### 5. 오라클 설정 및 데이터 로딩 ###

DMS을 이용하여 CDC 방식으로 데이터를 복제하기 위해서는 아래의 두가지 요건을 충족해야 한다.

* 아카이브 로그 모드 활성화
* supplemental 모드 활성화

데이터 로딩은 자동으로 빌드된 ec2 인스턴스 중, tf_loggen 이라는 이름을 가지 인스턴스로 로그인 한 후, 아래의 명령어를 이용하여 진행하면 된다.
스키마 생성 및 초기 데이터 로딩의 대상이 되는 오라클 데이터베이스의 IP 는, 자동으로 설정되기 때문에 아래의 명령어를 수행하기만 하면 된다. 

[오라클 설정 조회]
```
SQL> select name, log_mode, 
       supplemental_log_data_min, 
       supplemental_log_data_pk, 
       supplemental_log_data_ui, 
       supplemental_log_data_all from v$database
```

[supplemental logging 활성화]
```
SQL> alter database add supplemental log data;
SQL> alter database add supplemental log data (primary key) columns;
SQL> alter database add supplemental log data (unique) columns;
```
로그 마이너를 위한 최소한의 로깅과 update 시 레코드를 식별하기 위해 필요한 PK 또는 유니크 인덱스에 대한 supplemental logging 기능을 활성화 한다.
만약 복제 대상이 되는 테이블에 PK 또는 Non-NULL 유니크 인덱스 또는 제약조건이 없다면 전체 칼럼에 로깅된다. 
supplemental logging 에 대한 자세한 내용은 오라클 문서를 참조하도록 한다. 

* [Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D857AF96-AC24-4CA1-B620-8EA3DF30D72E.htm#SUTIL1582)
* [Database-Level Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D2DDD67C-E1CC-45A6-A2A7-198E4C142FA3.htm#SUTIL1583)

### 6. postgres 설정 ###

postgresql 은 default 로 로컬 접속만을 허용한다. 외부에서 접속하고자 하는 경우 아래와 같이 설정 파일 2개를 수정해야 한다.   
DMS 를 이용하여 오라클 데이터베이스의 변경 데이터를 복제하기 위해서는 postgresql 역시 데이터베이스, 테이블스페이스 및 접속 유저에 대한 설정이 필요하다.   
postgresql는 여러개의 작은 데이터베이스들로 구성이 되어져 있으며, 각각의 데이터베이스는 동일한 인스턴스에 의해 관리되지만, 실제로는 완전히 분리된 데이터베이스로
생각해야 하며, 서로 다른 데이터베이스 테이블간의 조인은 불가능하다.
오라클 12c 부터는 경우 PDB, CDB 구조로 되어 있어 postgresql 와 비슷한 데이터베이스 구조로 설계되어 있지만, 오라클 11g 의 겨우
하나의 데이터베이스로 설계되어져 있어서, postgresql 전환시 하나의 데이터베이스 매핑 되도록 해야 한다. 

* 외부 접속 설정
* 데이터베이스, 테이블 스페이스, 유저 생성

### 7. DMS 태스크 설정 ###

- binary reader

- log miner


### 8. DMS 모니터링하기 ###














