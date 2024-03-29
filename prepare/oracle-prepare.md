## 오라클 설정 ##

DMS을 이용하여 CDC 방식으로 오라클 데이터베이스의 데이터를 복제해 오기 위해서는 아래의 두가지 요건을 충족해야 합니다.

* 아카이브 로그 모드 전환
* supplemental 로깅 활성화

오라클 설정을 위해서는 tf_oracle_19c 서버로 ssh를 이용하여 로그인 한 후, 아래의 가이드에 따라 오라클 데이터베이스를 변경합니다.
추가적으로 11g 에 대한 마이그레이션 테스트를 수행하고자 하는 경우 tf_oracle_11xe 서버로 로그인 하여 동일한 작업을 수행합니다.

#### 5-1. 아카이브 로그 모드 전환 ####

오라클 데이터베이스를 아카이브 로그 모드로 전환하기 위해서는 해당 데이테베이스를 shutdown 한 후, mount 모드에서 아카이브 로그를 활성화 해줘야 합니다. 
운영중인 시스템인 경우 이미 아카이브 로그가 활성화 되어 있는 경우가 대부분이기 때문에 이 과정을 불필요할 수 있습니다. 
데이터베이스가 아카이브 로그로 운영중인지 확인이 필요한 경우 아래의 SQL 로 확인이 가능합니다. 
```
SQL> select name, log_mode from v$database;

NAME	  LOG_MODE
--------- ------------
CDB1	  NOARCHIVELOG
```

[아카이브 로그 전환]

아래의 예시는 오라클 11xe, 19c 별로 각각 아카이브 로그 모드로 데이터베이스를 전환하는 방법에 대한 예시입니다. 

* 19c
```
[ec2-user@ip-172-31-11-107 ~]$ sudo su - oracle

[oracle@ip-172-31-11-107 ~]$ sqlplus "/ as sysdba"

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Jan 26 10:53:17 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.

SQL> startup mount
ORACLE instance started.

Total System Global Area 1577057320 bytes
Fixed Size		    9137192 bytes
Variable Size		  520093696 bytes
Database Buffers	 1040187392 bytes
Redo Buffers		    7639040 bytes
Database mounted.

SQL> archive log list
Database log mode	       No Archive Mode
Automatic archival	       Disabled
Archive destination	       /app/oracle/product/19c/dbhome/dbs/arch
Oldest online log sequence     23
Current log sequence	       25

SQL> alter database archivelog;

Database altered.

SQL> archive log list
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       /app/oracle/product/19c/dbhome/dbs/arch
Oldest online log sequence     23
Next log sequence to archive   25
Current log sequence	       25

SQL> alter database open;
  
Database altered.
```

* 11xe
```
ubuntu@ip-172-31-32-20:~$ sudo su - oracle

oracle@ip-172-31-32-20:~$ sqlplus "/ as sysdba"

SQL*Plus: Release 11.2.0.2.0 Production on Mon Jan 25 07:37:09 2021

Copyright (c) 1982, 2011, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> startup mount          
ORACLE instance started.

Total System Global Area 1068937216 bytes
Fixed Size		    2233344 bytes
Variable Size		  822086656 bytes
Database Buffers	  239075328 bytes
Redo Buffers		    5541888 bytes
Database mounted.

SQL> alter database archivelog;

Database altered.

SQL> alter system set log_archive_dest_1 = 'location=/u01/app/oracle/oradata/arch' scope=both;

SQL> alter database open;

Database altered.

SQL> archive log list
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       /u01/app/oracle/oradata/arch
Oldest online log sequence     4
Next log sequence to archive   5
Current log sequence	       5
```

#### 5-2. supplemental 로깅 활성화 ####

[supplemental 로깅 상태 조회]
```
SQL> col log_min format a10
SQL> col log_pk format a10
SQL> col log_ui format a10
SQL> col log_all format a10

SQL> select name, log_mode, 
       supplemental_log_data_min as log_min, 
       supplemental_log_data_pk as log_pk, 
       supplemental_log_data_ui as log_ui, 
       supplemental_log_data_all as log_all from v$database;
       
NAME	  LOG_MODE     LOG_MIN	  LOG_PK     LOG_UI	LOG_ALL
--------- ------------ ---------- ---------- ---------- ----------
CDB1	  ARCHIVELOG NO	  NO	     NO 	NO
```

[supplemental logging 활성화]
```
SQL> alter database add supplemental log data;
SQL> alter database add supplemental log data (primary key) columns;
SQL> alter database add supplemental log data (unique) columns;


SQL> col log_min format a10
SQL> col log_pk format a10
SQL> col log_ui format a10
SQL> col log_all format a10

SQL> select name, log_mode, 
       supplemental_log_data_min as log_min, 
       supplemental_log_data_pk as log_pk, 
       supplemental_log_data_ui as log_ui, 
       supplemental_log_data_all as log_all from v$database;

NAME	  LOG_MODE     LOG_MIN	  LOG_PK     LOG_UI	LOG_ALL
--------- ------------ ---------- ---------- ---------- ----------
CDB1	  NOARCHIVELOG YES	  YES	     YES	NO
```

CDC 방식을 이용하여 변경 데이터를 오라클로 부터 읽어오기 위해서는 suppplemental 로깅이 활성화 되어 있어야 합니다. 
로그 마이너를 위한 최소한의 로깅과 update 시 레코드를 식별하기 위해 필요한 PK 또는 유니크 인덱스에 대한 supplemental logging 기능의 활성화가 필요합니다.
만약 복제 대상이 되는 테이블에 PK 또는 Non-NULL 유니크 인덱스 또는 제약조건이 없다면, update 수행시 레코드를 구분하기 위해 전체 칼럼이 로깅됩니다.  
마이그레이션 대상 테이블이고, PK 또는 유니크 인덱스 또는 제약조건이 없는 테이블인 경우, 변경 로그량을 줄이기 위해서 PK 또는 유니크 인덱스를 만드는 것을 고려해야 합니다. 

supplemental logging 에 대한 자세한 내용은 오라클 문서를 참조하도록 합니다. 

* [Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D857AF96-AC24-4CA1-B620-8EA3DF30D72E.htm#SUTIL1582)
* [Database-Level Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D2DDD67C-E1CC-45A6-A2A7-198E4C142FA3.htm#SUTIL1583)
