## Oracle / PostgreSQL 성능 비교 ##

이번 챕터에서는 hammerdb(https://www.hammerdb.com/download.html)를 이용하여 Oracle 데이터베이스와 PostgreSQL 간의 성능을 비교하도록 하겠습니다. hammerdb는 윈도우와 리눅스에서 동작하며, GUI 또는 CLI 형태로 시나리오를 작성하여 데이터베이스의 성능을 테스트할 수 있습니다. 하지만 윈도우 버전의 경우 PostgreSQL 은 문제가 없으나, Oracle를 대상으로 테스트하는 경우 HammerDB 가 동작하다가 죽기 때문에, GUI 모드를 이용하여 테스트 하고자 하는 유저는 레드헷 리눅스 계열의 OS 를 설치할 것을 권장합니다.   
Amazon Linux 2 에 GUI 를 구동시키기 위한 정보는 https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/ 를 참고하세요.

### 설치하기 ###

```
ubuntu@ip-172-31-1-141:~$ sudo apt-get install -y tcl-dev tk-dev unzip

ubuntu@ip-172-31-1-141:~$ wget download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

ubuntu@ip-172-31-1-141:~$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz
ubuntu@ip-172-31-1-141:~$ tar xvfz HammerDB-4.0-Linux.tar.gz
ubuntu@ip-172-31-1-141:~$ cd HammerDB-4.0
ubuntu@ip-172-31-1-141:~/HammerDB-4.0$ ./hammerdbcli 
HammerDB CLI v4.0
Copyright (C) 2003-2020 Steve Shaw
Type "help" for a list of commands
The xml is well-formed, applying configuration

hammerdb>quit
Shutting down HammerDB CLI
```

### 이슈 해결 ###

* https://stackoverflow.com/questions/40779757/connect-postgresql-to-hammerdb

* https://www.c-sharpcorner.com/article/top-database-performance-testing-tools/

* https://cloud.google.com/compute/docs/tutorials/load-testing-sql-server-hammerdb?hl=ko

* https://unioneinc.tistory.com/65

* https://www.hammerdb.com/docs/

* https://www.hammerdb.com/blog/uncategorized/hammerdb-command-line-build-and-test-examples/

* https://www.hammerdb.com/blog/uncategorized/driving-hammerdbcli-from-a-bash-script/

