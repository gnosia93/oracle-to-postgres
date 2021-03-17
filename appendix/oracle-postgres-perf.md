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

### GUI 설치 ###

* https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/

```
[ec2-user@ip-172-31-41-48 ~]$ sudo yum update

[ec2-user@ip-172-31-41-48 ~]$ sudo yum groupinstall "Development tools"

[ec2-user@ip-172-31-41-48 ~]$ sudo amazon-linux-extras install mate-desktop1.x

[ec2-user@ip-172-31-41-48 ~]$ echo "/usr/bin/mate-session" > ~/.Xclients && chmod +x ~/.Xclients

[ec2-user@ip-172-31-41-48 ~]$ sudo yum install tigervnc-server

[ec2-user@ip-172-31-41-48 ~]$ vncpasswd
vncpasswd
Password:
Verify:
Would you like to enter a view-only password (y/n)? n
A view-only password is not used

[ec2-user@ip-172-31-41-48 ~]$ sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service

[ec2-user@ip-172-31-41-48 system]$ sudo sed -i 's/<USER>/ec2-user/' /etc/systemd/system/vncserver@.service

[ec2-user@ip-172-31-41-48 system]$ sudo systemctl daemon-reload

[ec2-user@ip-172-31-41-48 system]$ sudo systemctl enable vncserver@:1
Created symlink from /etc/systemd/system/multi-user.target.wants/vncserver@:1.service to /etc/systemd/system/vncserver@.service.

[ec2-user@ip-172-31-41-48 system]$ sudo systemctl start vncserver@:1

[ec2-user@ip-172-31-41-48 system]$ sudo systemctl status vncserver@:1
● vncserver@:1.service - Remote desktop service (VNC)
   Loaded: loaded (/etc/systemd/system/vncserver@.service; enabled; vendor preset: disabled)
   Active: active (running) since 수 2021-03-17 02:57:52 UTC; 50s ago
  Process: 2450 ExecStartPre=/bin/sh -c /usr/bin/vncserver -kill %i > /dev/null 2>&1 || : (code=exited, status=0/SUCCESS)
 Main PID: 2454 (vncserver_wrapp)
   CGroup: /system.slice/system-vncserver.slice/vncserver@:1.service
           ├─2454 /bin/sh /usr/bin/vncserver_wrapper ec2-user :1
           └─2806 sleep 5

 3월 17 02:57:52 ip-172-31-41-48.ap-northeast-2.compute.internal systemd[1]: Starting Remote desktop service (VNC)...
 3월 17 02:57:52 ip-172-31-41-48.ap-northeast-2.compute.internal systemd[1]: Started Remote desktop service (VNC).
 3월 17 02:57:53 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: xauth:  file /home/ec2-user/.Xauthor...t
 3월 17 02:57:56 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: New 'ip-172-31-41-48.ap-northeast-2....1
 3월 17 02:57:56 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: Creating default startup script /hom...p
 3월 17 02:57:56 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: Creating default config /home/ec2-us...g
 3월 17 02:57:56 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: Starting applications specified in /...p
 3월 17 02:57:56 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: Log file is /home/ec2-user/.vnc/ip-1...g
 3월 17 02:58:01 ip-172-31-41-48.ap-northeast-2.compute.internal vncserver_wrapper[2454]: 'vncserver :1' has PID 2478, waiting....
Hint: Some lines were ellipsized, use -l to show in full.
```

### 내 PC 설정하기 ###

ssh 터널링을 통해서 VNC 클라이언트로 접속한다. 자세한 내용은 아래 URL 을 참고.

https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/


### HammerDB 설치하기 ###

```
[ec2-user@ip-172-31-41-48 ~]$ mkdir -p oracle/lib

[ec2-user@ip-172-31-41-48 ~]$ vi .bash_profile
ulimit -n 40960
export ORACLE_HOME=/home/ec2-user/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME

[ec2-user@ip-172-31-41-48 ~]$ . .bash_profile

[ec2-user@ip-172-31-41-48 ~]$ cd $ORACLE_HOME

[ec2-user@ip-172-31-41-48 oracle]$ vi tnsnames.ora
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

[ec2-user@ip-172-31-41-48 oracle]$ wget download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

[ec2-user@ip-172-31-41-48 oracle]$ unzip instantclient-basic-linux.x64-21.1.0.0.0.zip 

[ec2-user@ip-172-31-41-48 oracle]$ mv instantclient_21_1/ lib

[ec2-user@ip-172-31-41-48 oracle]$ cd

[ec2-user@ip-172-31-41-48 ~]$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz

[ec2-user@ip-172-31-41-48 ~]$ tar xvfz HammerDB-4.0-Linux.tar.gz

[ec2-user@ip-172-31-41-48 ~]$ cd HammerDB-4.0
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

