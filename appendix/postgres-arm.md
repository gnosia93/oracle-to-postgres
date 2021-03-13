## PostgreSQL on ARM EC2 ##

PostgreSQL 은 ARM 아키텍처를 오래전 부터 지원하고 있다. 아마존 EC2 Graviton2 인스턴스를 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보인다. 

#### Supported Version of Linux Distributions ####

* Unbutu 의 경우 - PostgreSQL 12 까지 지원
  https://www.postgresql.org/download/linux/ubuntu/

* CentOS 의 경우 - PostgreSQL 13 까지 지원
  https://www.postgresql.org/download/linux/redhat/
  
* Amazon Linux 2 의 경우 - PostgreSQL 11 까지 지원
  Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 11.5 이다.


### 테스트 아키텍처 ###













### 테스트 인프라 빌드하기 ###

- 이미지 정보 조회
```
aws ec2 describe-images --image-ids ami-00f1068284b9eca92
```

Graviton2 과 X86 용 PostgreSQL 11 의 성능 비교를 위해 아키텍처 다이어그램에 나와 있는 것 처럼, 아래 스크립트를 이용하여 인프라를 준비합니다.
R6g 타입의 인스턴스는 AWS 그라비톤2 프로세스를 탑재하고 있는데, X86 대비 40% 까지 저렴합니다.(https://aws.amazon.com/ko/ec2/instance-types/r6/),

 - c6g.8xlarge: 32 vCPU / 256 GB / 12 Gigabit (Graviton2)
 - r5.8xlarge: 32 vCPU / 256 GB / 12 Gigabit (X86-64) 

```
SG_ID=`aws ec2 describe-security-groups --group-names tf_sg_pub --query "SecurityGroups[0].{GroupId:GroupId}" --output text`; echo $SG_ID

ARM_AMI_ID=`aws ec2 describe-images \
                  --owners amazon \
                  --filters "Name=name, Values=amzn2-ami-hvm-2.0.20210303.0-arm64-gp2" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $ARM_AMI_ID

X64_AMI_AMZN2_ID=`aws ec2 describe-images \
                  --owners amazon \
                  --filters "Name=name, Values=amzn2-ami-hvm-2.0.20210303.0-x86_64-gp2" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $X64_AMI_AMZN2_ID

X64_AMI_UBUNTU_ID=`aws ec2 describe-images \
                  --owners 099720109477 \
                  --filters "Name=name, Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210223" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $X64_AMI_UBUNTU_ID


USER_DATA=`cat <<EOF | base64
#! /bin/bash
sudo amazon-linux-extras install postgresql11 epel -y
sudo yum install postgresql-server postgresql-contrib postgresql-devel -y
sudo -u ec2-user postgres --version >> /home/ec2-user/postgres.out
sudo postgresql-setup --initdb

sudo -u postgres sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" -i /var/lib/pgsql/data/postgresql.conf
sudo -u postgres sed -e "s/max_connections = 100/max_connections = 2000/" -i /var/lib/pgsql/data/postgresql.conf

sudo -u postgres sed -i -e "/is for Unix domain socket connections only/a\local   all             shop                        md5" /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/pgsql/data/pg_hba.conf

sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u ec2-user ps aux | grep postgres >> /home/ec2-user/postgres.out
EOF`


aws ec2 run-instances \
  --image-id $ARM_AMI_ID \
  --count 1 \
  --instance-type r6g.8xlarge \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=300, VolumeType=io2, Iops=50000}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cl_postgres_arm64}]' \
  --user-data $USER_DATA
  
aws ec2 run-instances \
  --image-id $X64_AMI_AMZN2_ID \
  --count 1 \
  --instance-type r5.8xlarge \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=300, VolumeType=io2, Iops=50000}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cl_postgres_x86-64}]' \
  --user-data $USER_DATA
  
aws ec2 run-instances \
  --image-id $X64_AMI_UBUNTU_ID \
  --count 1 \
  --instance-type r5.8xlarge \
  --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=50}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cl_stress-gen}]' \
  --user-data $USER_DATA    
```

### PostgreSQL 초기화 하기 ###

우선 cl_postgres_arm64 와 cl_postgres_x86-64 로 접속하여, sbtest 라는 이름의 데이터베이스와 유저를 생성합니다. 
```
[ec2-user@ip-172-31-43-151 etc]$ sudo su - postgres
-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# CREATE USER sbtest WITH PASSWORD 'sbtest';
CREATE ROLE
postgres=# CREATE DATABASE sbtest;
CREATE DATABASE
postgres=# GRANT ALL PRIVILEGES ON DATABASE sbtest TO sbtest;
GRANT
postgres=# \q
```

### sysbench 설치하기 ###

* https://severalnines.com/database-blog/how-benchmark-postgresql-performance-using-sysbench  
아래의 명령어를 참고하여 테스트 트래픽을 발생시키는 cl_stress-gen 인스턴스에 sysbench를 설치합니다. PostgreSQL 설치되는 EC2 가 amazon linux2 를 사용하는데 반해, 스트레스 트패릭을
생성하는 cl_stress-gen 서버는 우분투 입니다.

```
$ aws ec2 describe-instances --filters "Name=tag:Name,Values=cl_stress-gen"  --query "Reservations[].Instances[*].{InstanceId:InstanceId, PublicIpAddress:PublicIpAddress, Name:Tags[0].Value}" --output table
-------------------------------------------------------------
|                     DescribeInstances                     |
+---------------------+-----------------+-------------------+
|     InstanceId      |      Name       |  PublicIpAddress  |
+---------------------+-----------------+-------------------+
|  i-01296b0081a5a653d|  cl_stress-gen  |  3.35.131.217     |
+---------------------+-----------------+-------------------+

$ ssh -i ~/.ssh/tf_key ubuntu@3.35.131.217

ubuntu@ip-172-31-1-64:~$ curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash

ubuntu@ip-172-31-1-64:~$ sudo apt -y install sysbench

ubuntu@ip-172-31-1-64:~$ sysbench --version
sysbench 1.0.20
```

### 성능 테스트 하기 ###
아래의 스크립트를 실행하여 각 데이터베이스의 성능을 측정합니다. 이 때 TARGET_DB 는 성능 측정의 대상이 되는 PostgreSQL 의 IP로 반드시 EC2 인스턴스의 사설 IP 를 입력해야 합니다.
THREAD_COUNT 는 sysbench 가 테스트를 위해 내부적으로 생성하는 쓰레드의 수로, 데이터베이스 커넥션수와 같습니다.
쓰레드 수를 32 을 시작으로 64, 128, 256, 512 까지 두배씩 증가 시키면서 두 데이터베이스의 성능을 측정한 후 비교하도록 합니다.   
참고로 아래 테스트 스크립트를 보면 prepare, run, cleanup 이라는 키워드를 볼 수 있은데, prepare 은 테스트를 위한 스키마 빌드 작업을 하는 단계이고, 실제 테스트는 run 단계에서 
수행됩니다. cleanup 명령어를 사용하면 prepare 단계에서 생성한 각종 DB오브젝트를 삭제합니다.
```
export TARGET_DB=172.31.21.182
export THREAD_COUNT = 64

$ sysbench \
--db-driver=pgsql \
--table-size=5000000 \
--tables=32 \
--threads=1 \
--pgsql-host=$TARGET_DB \
--pgsql-port=5432 \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/oltp_read_write.lua prepare

$ sysbench \
--db-driver=pgsql \
--report-interval=10 \
--table-size=5000000 \
--tables=32 \
--threads=$THREAD_COUNT \
--time=120 \
--pgsql-host=$TARGET_DB \
--pgsql-port=5432 \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/oltp_read_write.lua run

$ sysbench \
--db-driver=pgsql \
--report-interval=10 \
--table-size=5000000 \
--tables=32 \
--threads=$THREAD_COUNT \
--time=120 \
--pgsql-host=$TARGET_DB \
--pgsql-port=5432 \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/oltp_read_write.lua cleanup
```

- 테스트 결과(X86)
```
SQL statistics:
    queries performed:
        read:                            7657300
        write:                           2187706
        other:                           1093956
        total:                           10938962
    transactions:                        546931 (4555.12 per sec.)
    queries:                             10938962 (91105.22 per sec.)
    ignored errors:                      19     (0.16 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          120.0683s
    total number of events:              546931
```

