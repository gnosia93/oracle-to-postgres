# Oracle to Postgres Migration Workshop #

이 튜토리얼은 AWS DMS 서비스를 이용한 oracle to Postgres 마이그레이션 전체 과정에 대한 이해를 돕기 위해 만들어 졌습니다.   
컨텐츠의 대부분은 Mac OS 기준으로 작성되었으며, 테라폼을 이용하여 실습용 인프라를 빌드 합니다. 테라폼과 관련 정보는 https://www.terraform.io/ 에서 확인할 수 있고, 
본 튜토리얼에서는 테라폼에 대한 내용은 다루지 않습니다.  

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

오라클의 경우 약 30분 정도의 시간이 걸린다. 

```
var.tf 수정 (내아이피를 확인한 후)
$ terraform apply -auto-approve
```

### 5. 오라클 사전 준비 ###


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


### 8. SCT ###

옵션널 한 단계인 SCT 에 대해서 다룬다. 


### 9. DMS ###

* [DMS 설정하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-settings.md)

* [DMS 동작 모니터링하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-monitoring.md)












