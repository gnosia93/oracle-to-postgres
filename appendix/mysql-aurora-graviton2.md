## Performance of Amazon Aurora MySQL ##

### 데이터베이스 생성 ###

이번 챕터에서는 graviton2(r6g.) 와 x64(r5.) 를 대상으로 그 사이즈가 2x ~ 16x 사이에 있는 인스턴스를 대상으로 성능테스트를 수행합니다. 
성능 테스트시 적용되는 Aurora MySQL 데이터베이스의 파리미터 값은 다음과 같습니다. 운영 환경에서 쓰레드 구조로 동작하는 MySQL 의 경우 통상 physical memory 의 최대 75% 까지 innodb_buffer_pool 을 설정하나, 이번 테스트에서는 40GB 만 설정합니다. 
```
[mysql.conf]
  innodb_buffer_pool_size = 42949672960      -- byte 단위로 설정 (40GB)
  max_connections = 2000
```

데이터베이스를 생성하기 위해 아래의 스크립트를 순차적으로 실행합니다. (2xlarge ~ 16xlarge 까지 테스트할 예정이므로, 인스턴스 사이즈에 맞게 아래 스크립트를 변경한 후 실행합니다.)

```
$ aws rds describe-db-engine-versions --default-only --engine aurora-mysql
5.7.mysql_aurora.2.09.2

$ aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily"
aurora-mysql5.7

$ aws rds create-db-parameter-group \
     --db-parameter-group-name pg-aurora-mysql \
     --db-parameter-group-family aurora-mysql5.7 \
     --description "My Aurora MySQL new parameter group"

$ aws rds modify-db-parameter-group \
    --db-parameter-group-name pg-aurora-mysql \
    --parameters "ParameterName='innodb_buffer_pool_size',ParameterValue=42949672960,ApplyMethod=pending-reboot" \
                 "ParameterName='max_connections',ParameterValue=2000,ApplyMethod=pending-reboot"   

$ aws ec2 create-security-group --group-name sg_aurora_mysql --description "aurora mysql security group"
{
    "GroupId": "sg-0518761208b6e516f"
}

$ aws ec2 authorize-security-group-ingress --group-name sg_aurora_mysql --protocol tcp --port 3306 --cidr 0.0.0.0/0

$ sleep 10       #   (10초 대기)                    
                                        
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-mysql-graviton2-16x \
    --engine aurora-mysql \
    --engine-version 5.7.mysql_aurora.2.09.2 \
    --master-username myadmin \
    --master-user-password myadmin1234 \
    --vpc-security-group-ids sg-0518761208b6e516f          

$ aws rds create-db-instance \
    --db-cluster-identifier aurora-mysql-graviton2-16x \
    --db-instance-identifier aurora-mysql-graviton2-16x-1 \
    --db-instance-class db.r6g.16xlarge \
    --engine aurora-mysql \
    --db-parameter-group-name pg-aurora-mysql
    
    
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-postgres-x64-16x \
    --engine aurora-mysql \
    --engine-version 5.7.mysql_aurora.2.09.2 \
    --master-username myadmin \
    --master-user-password myadmin \
    --vpc-security-group-ids sg-0518761208b6e516f
    
$ aws rds create-db-instance \
    --db-cluster-identifier aurora-postgres-x64-16x \
    --db-instance-identifier aurora-postgres-x64-16x-1 \
    --db-instance-class db.r5.16xlarge \
    --engine aurora-mysql \
    --db-parameter-group-name pg-aurora-mysql
    
```


### Aurora 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-graviton2-4x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-postgres-graviton2-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-x64-4x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-postgres-x64-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

psql 클라이언트 프로램으로 aurora-postgres-graviton2-8x-1, aurora-postgres-x64-8x-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install postgresql-client

ubuntu@ip-172-31-45-65:~$ psql -V
psql (PostgreSQL) 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)

ubuntu@ip-172-31-45-65:~$ psql -h aurora-postgres-graviton2-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -U postgres
Password for user postgres: 
psql (12.6 (Ubuntu 12.6-0ubuntu0.20.04.1), server 12.4)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=> select version();
                                                   version                                                   
-------------------------------------------------------------------------------------------------------------
 PostgreSQL 12.4 on aarch64-unknown-linux-gnu, compiled by aarch64-unknown-linux-gnu-gcc (GCC) 7.4.0, 64-bit
(1 row)

postgres=> CREATE USER sbtest WITH PASSWORD 'sbtest';
CREATE ROLE
postgres=> CREATE DATABASE sbtest;
CREATE DATABASE
postgres=> GRANT ALL PRIVILEGES ON DATABASE sbtest TO sbtest;
GRANT
postgres=> \q
```



성능 테스트 방법은 기존과 동일하다. [테스트 자동화하기] 섹션에 나온대로 perf.sh 파일을 만들고, 대상 데이터베이스의 주소를 변경한 다음 실행한다. 

### 테스트 결과 ###

* X64
 
[aurora-postgres-x64-16x-1] - cpu 79%
```
```


* graviton2   


[aurora-postgres-graviton2-16x-1] - cpu 77%
```
```


