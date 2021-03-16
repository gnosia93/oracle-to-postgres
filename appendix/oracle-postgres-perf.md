## Oracle / PostgreSQL 성능 비교 ##

이번 챕터에서는 hammerdb(https://www.hammerdb.com/download.html)를 이용하여 Oracle 데이터베이스와 PostgreSQL 간의 성능을 비교하도록 하겠습니다. hammerdb는 윈도우와 리눅스에서 동작하며, GUI 또는 CLI 형태로 시나리오를 작성하여 데이터베이스의 성능을 테스트할 수 있습니다. 하지만 윈도우 버전의 경우 PostgreSQL 은 문제가 없으나, Oracle를 대상으로 테스트하는 경우 HammerDB 가 동작하다가 죽기 때문에, GUI 모드를 이용하여 테스트 하고자 하는 유저는 레드헷 리눅스 계열의 OS 를 설치할 것을 권장합니다.   
Amazon Linux 2 에 GUI 를 구동시키기 위한 정보는 https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/ 를 참고하세요.

### 설치하기 ###

```
ubuntu@ip-172-31-1-141:~$ sudo apt-get install -y tcl-dev tk-dev unzip

ubuntu@ip-172-31-1-141:~$ wget download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

ubuntu@ip-172-31-1-141:~$ unzip instantclient-basic-linux.x64-21.1.0.0.0.zip 

ubuntu@ip-172-31-1-141:~$ vi .bash_profile
ulimit -n 40960
export ORACLE_HOME=/home/ubuntu/instantclient_21_1
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
    
ubuntu@ip-172-31-1-141:~$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-1-141:~$ tar xvfz HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-1-141:~$ cd HammerDB-4.0

ubuntu@ip-172-31-1-141:~/HammerDB-4.0$ cd config/

ubuntu@ip-172-31-1-141:~/HammerDB-4.0$ vi oracle.xml
```
 1 <?xml version="1.0" encoding="utf-8"?>
  2 <oracle>
  3     <connection>
  4         <system_user>system</system_user>
  5         <system_password>manager</system_password>
  6         <instance>pdb1</instance>                        <--- pdb1 으로 수정
  7         <rac>0</rac>
  8     </connection>
  9     <tpcc>
 10         <schema>
 11             <count_ware>16</count_ware>                  <--- 16 으로 수정 
 12             <num_vu>1</num_vu>
 13             <tpcc_user>tpcc</tpcc_user>
 14             <tpcc_pass>tpcc</tpcc_pass>
 15             <tpcc_def_tab>tpcctab</tpcc_def_tab>
 16             <tpcc_ol_tab>tpcctab</tpcc_ol_tab>
 17             <tpcc_def_temp>temp</tpcc_def_temp>
 18             <partition>false</partition>
 19             <hash_clusters>false</hash_clusters>
 20             <tpcc_tt_compat>false</tpcc_tt_compat>
 21         </schema>
 22         <driver>
 23             <total_iterations>1000000</total_iterations>
 24             <raiseerror>false</raiseerror>
 25             <keyandthink>false</keyandthink>
 26             <checkpoint>false</checkpoint>
 27             <ora_driver>test</ora_driver>
 28             <rampup>2</rampup>
 29             <duration>5</duration>
 30             <allwarehouse>false</allwarehouse>
 31             <timeprofile>false</timeprofile>
 32             <async_scale>false</async_scale>
 33             <async_client>10</async_client>
 34             <async_verbose>false</async_verbose>
 35             <async_delay>1000</async_delay>
 36             <connect_pool>false</connect_pool>
 37         </driver>
 38     </tpcc>
 39     <tpch>
 40         <schema>
 41             <scale_fact>16</scale_fact>                   <--- 16 으로 수정
 42             <tpch_user>tpch</tpch_user>
 43             <tpch_pass>tpch</tpch_pass>
 44             <tpch_def_tab>tpchtab</tpch_def_tab>
 45             <tpch_def_temp>temp</tpch_def_temp>
 46             <num_tpch_threads>1</num_tpch_threads>
 47             <tpch_tt_compat>false</tpch_tt_compat>
 48         </schema>
 49         <driver>
 50             <total_querysets>1</total_querysets>
 51             <raise_query_error>false</raise_query_error>
 52             <verbose>false</verbose>
 53             <degree_of_parallel>2</degree_of_parallel>
 54             <refresh_on>false</refresh_on>
 55             <update_sets>1</update_sets>
 56             <trickle_refresh>1000</trickle_refresh>
 57             <refresh_verbose>false</refresh_verbose>
 58             <cloud_query>false</cloud_query>
 59         </driver>
 60     </tpch>
 61 </oracle>
```

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

