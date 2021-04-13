## Oracle / PostgreSQL 성능 비교 ##

이번 챕터에서는 hammerdb(https://www.hammerdb.com/download.html)를 이용하여 Oracle 데이터베이스와 PostgreSQL 간의 성능을 비교하도록 하겠습니다. hammerdb는 윈도우와 리눅스에서 동작하며, GUI 또는 CLI 형태로 시나리오를 작성하여 데이터베이스의 성능을 테스트할 수 있습니다. 하지만 윈도우 버전의 경우 PostgreSQL 은 문제가 없으나, Oracle를 대상으로 테스트하는 경우 HammerDB 가 동작하다가 죽기 때문에, GUI 모드를 이용하여 테스트 하고자 하는 유저는 레드헷 리눅스 계열의 OS 를 설치할 것을 권장합니다.   
이 테스트 시나리오에서는 우분투를 이용하여 테스트 합니다.  
Amazon Linux 2 에 GUI 를 구동시키기 위한 정보는 https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/ 를 참고하세요.



### GUI 설치 및 VNC 설정 ###

```
ubuntu@ip-172-31-8-174:~$ sudo apt-get update; sudo apt-get upgrade

ubuntu@ip-172-31-8-174:~$ sudo apt-get install --no-install-recommends ubuntu-desktop

ubuntu@ip-172-31-8-174:~$ sudo apt-get install tigervnc-standalone-server tigervnc-xorg-extension

ubuntu@ip-172-31-8-174:~$ vncpasswd
vncpasswd
Password:
Verify:
Would you like to enter a view-only password (y/n)? n
A view-only password is not used

ubuntu@ip-172-31-8-174:~$ vi .vnc/xstartup
#!/bin/sh
# Start Gnome 3 Desktop
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
vncconfig -iconic &
dbus-launch --exit-with-session gnome-session &

ubuntu@ip-172-31-8-174:~$ vncserver -localhost no
/usr/bin/xauth:  file /home/ubuntu/.Xauthority does not exist

New 'ip-172-31-8-174.ap-northeast-2.compute.internal:1 (ubuntu)' desktop at :1 on machine ip-172-31-8-174.ap-northeast-2.compute.internal

Starting applications specified in /home/ubuntu/.vnc/xstartup
Log file is /home/ubuntu/.vnc/ip-172-31-8-174.ap-northeast-2.compute.internal:1.log

Use xtigervncviewer -SecurityTypes VncAuth,TLSVnc -passwd /home/ubuntu/.vnc/passwd ip-172-31-8-174.ap-northeast-2.compute.internal:1 to connect to the VNC server.

ubuntu@ip-172-31-8-174:~$ vncserver -list

TigerVNC server sessions:

X DISPLAY #	RFB PORT #	PROCESS ID
:1		5901		13208
```

### 터널링을 통한 GUI 서버 접속 ###

먼저 로컬 PC 에 vnc viewer 를 다운로드 받습니다. (https://www.realvnc.com/en/connect/download/viewer/) 
![vnc-viwer](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/vnc-viewer.png)

ssh 를 이용하여 서버와 터널링을 맺어 줍니다. 
```
$ ssh -L 5901:localhost:5901 -i ~/.ssh/tf_key ubuntu@3.35.13.129
```

로컬 PC 에서 VNC 클라이언트를 실행한 후 VNC 서버의 호스트 이름을 묻는 메시지가 표시되면 localhost: 1을 입력하여 서버로 연결합니다. 

vncpasswd 를 이용해서 설정했던 패스워드를 입력합니다. VNC 데이터는 기본적으로 암호화되지 않지만 여기에서는 SSH 터널을 사용하므로, 안전합니다. 


### HammerDB 설치하기 ###

아래 명령어를 참고하여 HammerDB 를 설치하고, 오라클 TNS 설정을 하도록 합니다. 
```
ubuntu@ip-172-31-8-174:~$ mkdir -p oracle

ubuntu@ip-172-31-8-174:~$ vi .bash_profile
ulimit -n 40960
export ORACLE_HOME=/home/ec2-user/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME

ubuntu@ip-172-31-8-174:~$ . .bash_profile

ubuntu@ip-172-31-8-174:~$ cd $ORACLE_HOME

ubuntu@ip-172-31-8-174:~/oracle$ vi tnsnames.ora
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

ubuntu@ip-172-31-8-174:~/oracle$ wget download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

ubuntu@ip-172-31-8-174:~/oracle$ unzip instantclient-basic-linux.x64-21.1.0.0.0.zip 

ubuntu@ip-172-31-8-174:~/oracle$ mv instantclient_21_1/ lib

ubuntu@ip-172-31-8-174:~/oracle$ cd

ubuntu@ip-172-31-8-174:~$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-8-174:~$ tar xvfz HammerDB-4.0-Linux.tar.gz
```

### HammerDB 실행하기 ###

![hammerdb-vnc](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/hammerdb-vnc.png)

VNC 클라이언트 상에서 아래의 명령으로 HammerDB GUI 버전을 실행합니다. 
```
ubuntu@ip-172-31-8-174:~$ cd HammerDB-4.0

ubuntu@ip-172-31-8-174:~$ ./Hammerdb
```




### CLI 로 실행하기  ###

* 시나리오 작성하기 
oracle_test.tcl 을 아래의 내용을 생성합니다. 
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
* 테스트 실행하기 
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

