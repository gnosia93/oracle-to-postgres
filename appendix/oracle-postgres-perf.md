## Oracle / PostgreSQL 성능 비교 ##

이번 챕터에서는 hammerdb(https://www.hammerdb.com/download.html)를 이용하여 Oracle 데이터베이스와 PostgreSQL 간의 성능을 비교하도록 하겠습니다. hammerdb는 윈도우와 리눅스에서 동작하며, GUI 또는 CLI 형태로 시나리오를 작성하여 데이터베이스의 성능을 테스트할 수 있습니다. 하지만 윈도우 버전의 경우 PostgreSQL 은 문제가 없으나, Oracle를 대상으로 테스트하는 경우 HammerDB 가 동작하다가 죽기 때문에, GUI 모드를 이용하여 테스트 하고자 하는 유저는 레드헷 리눅스 계열의 OS 를 설치할 것을 권장합니다.   
Amazon Linux 2 에 GUI 를 구동시키기 위한 정보는 https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/ 를 참고하세요.

### 인프라 빌드하기 ###

```
SG_ID=`aws ec2 describe-security-groups --group-names tf_sg_pub --query "SecurityGroups[0].{GroupId:GroupId}" --output text`; echo $SG_ID

ARM_AMI_ID=`aws ec2 describe-images \
                  --owners amazon \
                  --filters "Name=name, Values=amzn2-ami-hvm-2.0.20210303.0-arm64-gp2" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $ARM_AMI_ID

USER_DATA=`cat <<EOF | base64
#! /bin/bash
sudo amazon-linux-extras install postgresql11 epel -y
EOF`

aws ec2 run-instances \
  --image-id $ARM_AMI_ID \
  --count 1 \
  --instance-type r6g.4xlarge \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=600, VolumeType=io1, Iops=30000}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bm_hammerdb}]' \
  --user-data $USER_DATA
  

```












### 설치하기 ###

```
ubuntu@ip-172-31-1-141:~$ sudo apt-get install -y tcl-dev tk-dev unzip

ubuntu@ip-172-31-1-141:~$ mkdir -p oracle/lib

ubuntu@ip-172-31-1-141:~$ vi .bash_profile
ulimit -n 40960
export ORACLE_HOME=/home/ubuntu/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME

ubuntu@ip-172-31-1-141:~$ . .bash_profile

ubuntu@ip-172-31-1-141:~$ cd $ORACLE_HOME

ubuntu@ip-172-31-1-141:~$ vi tnsnames.ora
# <19c-oracle-private-ip> 를 오라클 사설 IP 로 수정해 주세요.
pdb1 =
    (DESCRIPTION =
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = <19c-oracle-private-ip>)(PORT = 1521))
        )
        (CONNECT_DATA =
            (SERVER = DEDICATED)
            (SERVICE_NAME = pdb1)
        )
    )

ubuntu@ip-172-31-1-141:~$ wget download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

ubuntu@ip-172-31-1-141:~$ unzip instantclient-basic-linux.x64-21.1.0.0.0.zip lib

ubuntu@ip-172-31-1-141:~$ cd

ubuntu@ip-172-31-1-141:~$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-1-141:~$ tar xvfz HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-1-141:~$ cd HammerDB-4.0
```

### 테스트 시나리오 만들기 ###

[oracle_test.tcl]
```
#!/usr/bin/tclsh

dbset db ora

diset connection system_user system
diset connection system_password manager
diset connection instance pdb1

diset tpcc count_ware 16
diset tpcc num_vu 16
diset tpcc tpcc_user tpcc7
diset tpcc tpcc_pass tpcc7
diset tpcc tpcc_def_tab tpcctab
diset tpcc tpcc_ol_tab tpcctab
diset tpcc tpcc_def_temp temp
diset tpcc total_iterations 1000000
diset tpcc ora_driver timed
diset tpcc rampup 2
diset tpcc duration 5

print dict
buildschema
waittocomplete

loadscript

vuset vu 16
vuset showoutput 1
vuset logtotemp 1

vucreate
vustatus
vurun
```

### 테스트 실행하기 ###
```
#!/bin/bash

echo "hammerdb start ..."
./hammerdbcli <<!
source oracle_test.tcl
!
echo "hammerdb end ..."

```

### 레퍼런스 ###

* https://www.hammerdb.com/docs/

* https://cloud.google.com/compute/docs/tutorials/load-testing-sql-server-hammerdb?hl=ko

* https://www.hammerdb.com/blog/uncategorized/hammerdb-command-line-build-and-test-examples/

* https://www.hammerdb.com/blog/uncategorized/driving-hammerdbcli-from-a-bash-script/

