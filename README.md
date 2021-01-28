# Oracle to Postgres Migration Workshop #

이 튜토리얼은 AWS DMS 서비스를 이용한 oracle to Postgres 마이그레이션 전체 과정에 대한 이해를 돕기 위해 만들어 졌습니다.   
본 튜토리얼은 여러분이 사용하는 클라리언트 PC 가 Mac OS 임 가정하고 작성되었으며, 테스트에 필요한 인프라의 경우 테라폼 스크립트를 이용하여 자동빌드하며,
반복적이고 빠른 테스트를 위해 AWS Console 화면을 통한 조작은 최소화 하였습니다.  
테라폼과 관련 정보는 https://www.terraform.io/ 에서 확인할 수 있고, 본문에서는 테라폼 사용법에 대한 내용은 다루지 않습니다.  
기존에 AWS 콘솔과 오라클 데이터베이스에 대한 사전 경험 있다는 가정하에 작성되었으며, postgresql 의 경우 사전 지식이 없더라도 마이그레이션과 관련된 정보를 습득할 수 있습니다. 

* 마이그레이션 프로세스
* 어플리케이션 변환 가이드
* postgresql 어드민 가이드

## 실습 아키텍처 ##

![architecture](https://github.com/gnosia93/postgres-terraform/blob/main/images/oracle-to-postgres-architecture.png)

* EC2 서버들이 배치되는 네트워크는 별도로 생성하지 않으며 계정별로 제공되는 기본 VPC 및 해당 VPC의 public 서브넷을 사용합니다. 

* 마이그레이션 테스트를 위해 오라클, postgres, DMS 로 구성된 테스트 세트는 11xe 용과 19c 용으로 2세트로 구성되며, 테라폼에 의해 빌드됩니다. (아키텍처 다이어그램에는 19c만 표시)

* 오라클 12C 부터는 CDB / PDB 아키텍처를 채용하고 있는데, Oracle Log Miner의 경우 PDB를 지원하지 않는 관계로 19C 의 경우 binary reader 방식으로 데이터를 복제하고, 11g의 경우 Log Miner 방식을 사용합니다.

* 트랜잭션 로그 전체를 DMS 로 전달하는 binary reader 방식에 비해, Oracle Log Miner 복제 방식은 원본 데이터베이스인 오라클 데이터베이스 CPU 를 좀 더 많이 사용하게 됩니다. 이는 원본 데이터베이스에서 복제 설정시 구성된 복제 항목에 따라 필터링을 먼저 수행한 후, DMS 로 해당 로그 데이터만 카피하는 구조로 되어 있기 때문이고, 오라클 로그 마이너는 원본 DB 의 변경이 많은 경우, 원본 데이터베이스의 성능에 영향을 주게 됩니다. 

* 샘플 스키마 및 초기 데이터 로딩 작업은 tf_loadgen EC2 인스턴스가 수행하고, 샘플 스키마 빌드는 sqlplus 와 shell script 로 구현되어 있으며, 초기 데이터 로딩은 python 으로 구현된 pyoracle 이라는 프로그램을 사용하게 됩니다. 

* Network bandwidth 는 마이그레이션 성능에 영향은 주는 주요 요소중에 하나 입니다. 이번 워크샵에서는 원본 및 타켓 데이터베이스가 동일한 VPC 에 존재하므로, 네트웍에 의한 성능 저하 이슈는 다루지 않습니다. 

* 통상적으로 onprem의 오라클 데이터베이스를 AWS로 이전시 마이그레이션을 위한 네트워크는 VPN(1.2Gbps/s) 또는 DX(Max 40Gbps/s) 를 사용하게 되는데, 허용 가능한 서비스 다운타임에 따라 네트워크의 종류와 bandwidth 를 선택하게 됩니다. 마이그레이션을 위한 네트워크 아키텍처는 초기 데이터 로딩량과 변경 데이터량(ongoing 데이터 적재량)을 고려하여 설계하여야 합니다. 


## 목차 ##

### 1. 소프트웨어설치 ###

튜토리얼을 진행하기 위해 테라폼, git 및 postgresql client 인 pgadmin 4 와 오라클 접속을 위한 sql developer 설치가 필요합니다.   
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

오라클의 경우 약 30분 정도의 시간이 걸린다. 

```
var.tf 수정 (내아이피를 확인한 후)
$ terraform apply -auto-approve
```

### 5. 오라클 사전 준비 ###

* https://github.com/gnosia93/postgres-terraform/blob/main/oracle/oracle-prepare.md


### 6. postgres 사전 준비 ###

* [유저/테이블스페이스/데이터베이스생성하기](https://github.com/gnosia93/postgres-terraform/blob/main/postgres/postgres-conf.md)


### 7. 오라클 데이터 로딩 ###

#### 7-1. 스키마 생성하기 ####

소스 DB 인 오라클데이터베이스에 실습용 스키마를 생성하고, 샘플 데이터를 로딩하기 위해서 tf_loadgen 서버로 로그인 한 후,  
아래 명령어를 실행한다. 

```
(base) f8ffc2077dc2:~ soonbeom$ ssh -i ~/.ssh/tf_key ec2-user@3.34.179.8

[ec2-user@ip-172-31-37-6 ~]$ cd pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh create-schema.sh 
find and replace oracle ip ... /home/ec2-user/oracle/tnsnames.ora
find and replace oracle ip ... /home/ec2-user/pyoracle/config.ini

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 25 08:16:52 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production


Tablespace dropped.


Tablespace created.


User dropped.


User created.


Grant succeeded.


Sequence created.


Sequence created.


Sequence created.


Table created.


Table created.


Index created.


Table created.


Index created.


Table created.


Table created.

SQL> 
```

#### 7-2. 샘플 데이터 생성 및 확인하기 ####

오라클 데이터베이스를 초기화하기 위해 init_11xe.sh 과 init_19c.sh 프로그램을 실행한다. 

상품 정보를 저장하는 tb_product 테이블에는 1000건을 저장하게되고, 주문 데이터를 생성하기 위해 50개의 클라이언트가 만들어지고, 클라이언트당 최대 100만개의 주문 정보를 생성하게 된다. 

[샘플 데이터 생성 예제]
```
[ec2-user@ip-172-31-37-6 pyoracle]$ pwd
/home/ec2-user/pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh init_11xe.sh
ORACLE_DB_URL: shop/shop@172.31.32.20:1521/xe
DATA_PATH" /home/ec2-user/pyoracle/images
PRODUCT_DESCRIPTION_HTML_PATH: /home/ec2-user/pyoracle/images/product_body.html
DEFAULT_PRODUCT_COUNT: 1000
DEFAULT_ORDER_COUNT: 1000000
loading product table... 
```

오라클 서버로 로그인해서 데이터가 제대로 생성되는 지 확인한다 . 

[데이터 생성 확인]
```
SQL> select count(1) from shop.tb_product;
SQL> select count(1) from shop.tb_order;
```


### 8. 스키마 변환(/w SCT) ###

* [데이터 오브젝트 변환](https://github.com/gnosia93/postgres-terraform/blob/main/sct/data-object-mapping.md)

* [코드 오브젝트 변환](https://github.com/gnosia93/postgres-terraform/blob/main/sct/code-object-mapping.md)


### 9. 데이터 이관(/w DMS) ###

* [DMS 설정하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-settings.md)

* [DMS 태스크 실행하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-task-start.md)

* [DMS 동작 모니터링하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-monitoring.md)


### 10. postgres 스트레스 테스트 ###

마이그레이션 완료 후 아파치 JMeter 를 활용하여 postgresql 의 성능을 측정한다. 


### 11. postgres 진단 ###

* performance assessment
* identifiy slow query / sql tunning


### 12. postgres 어드민 ###

```
▶ Postgresql System Catalogs (시스템 카탈로그)
pg_class : 테이블, 인덱스, 시퀀스, 뷰
pg_constraint : 제약조건
pg_database : 해당 클러스터에 속한 데이터베이스
pg_extension : 설치된 extension
pg_index : 상세 인덱스
pg_namespace : 스키마
pg_tablespace : 해당 클러스터에 속한 데이터베이스


▶ Postgresql System Views (시스템 뷰)
pg_available_extensions : 사용 가능한 extension
pg_file_settings : 파일 컨텐츠 구성 요약
pg_grouop : 데이터베이스 사용자 그룹
pg_indexes : 인덱스
pg_roles : 데이터베이스 롤
pg_settings : 구성 파라미터
pg_shadow : 데이터베이스 사용자
pg_stats : 플래너 통계
pg_tables : 테이블
pg_timezone_name : 타임존 명
pg_user : 데이터베이스 사용자
pg_views : 뷰
```

## 레퍼런스 ##

* https://stricky.tistory.com/367

* https://aws.amazon.com/ko/blogs/korea/how-to-migrate-your-oracle-database-to-postgresql/

* https://github.com/experdb/eXperDB-DB2PG

* https://www.enterprisedb.com/blog/the-complete-oracle-to-postgresql-migration-guide-tutorial-move-convert-database-oracle-alternative?gclid=CjwKCAiAouD_BRBIEiwALhJH6EYfjIYgfljHPqXSBbnmgypKWRxzegJ7hbYfSb_vAxrj2ywcVu1C7xoCOpwQAvD_BwE&utm_campaign=Q42020_APAC&utm_medium=cpc&utm_source=google


## Revision History 

- 2021.2.1 V0.1 first draft released 







