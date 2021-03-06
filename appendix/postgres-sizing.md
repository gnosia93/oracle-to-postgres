
원본이 싱글이냐, RAC 냐.. RAC 이면 A-S 모드이냐. A-A 모드이냐 에 따라 다르다... 경우에 따라서는 노드하나가 죽으면 fail-over 받을수 없을 정도로 용량을 꽉 채워서 쓰고 있는 경우도 있다. 
CPU, Memory 용량은 위의 근거로 해서 본다.
AWR Report 로 확인할 수 있는 사항은 ?
Disk 용량에 대해서는 신경 쓸 필요가 없고, IOPS 에 대해서는 신경 써야 한다..
Network 성능은.. EC2 인스턴스 타입에 따라 틀리다.. 

* 실행되는 SQL 수
* 데이터베이스 볼륨.
* 리두 로그 사이즈..
* SGA 사이즈.
* 클라이언트 수.
* SQL 파싱 ??
* 래치 / 경합..
* IBM 이냐. SAN 성능.
----------------------------
  - 오라클 진단/평가
      - 어느 정도 사용하고 있는지 ? (성능/용량)
      
-----

* https://aws.amazon.com/ko/blogs/database/best-practices-for-migrating-an-oracle-database-to-amazon-rds-postgresql-or-amazon-aurora-postgresql-migration-process-and-infrastructure-considerations/
-----
https://wiki.postgresql.org/wiki/Oracle_to_Postgres_Conversion

### Oracle Enterprise and RAC Considerations ###
Oracle Enterprise has a more direct migration to PostgreSQL than does Oracle Real Application Clusters (RAC) in some cases. With RAC you may have multiple, separate, heavy-hitting, DML applications usually of the OLTP type connected to the same RAC Cluster, where RAC serves as a type of application farm. A common mistake with migrations from Oracle RAC farms is to associate all of the farm applications with one PostgreSQL Instance. The big picture that is missed here is ACTIVE-ACTIVE (Oracle RAC) and ACTIVE-PASSIVE (PG). While Oracle RAC can divvy up the applications and load balance them across the Nodes in the cluster, there is no such thing in PostgreSQL. So, the "right" solution without some re-architecture and/or use of 3rd party tools and extensions is to migrate the applications off of Oracle RAC one at a time to separate PostgreSQL instances, one heavy-hitting application per PostgreSQL Instance. The next two sections illustrate CPU and Memory factors that come into play with PostgreSQL being a host to 2 or more heavy-hitting applications.

### CPU Contention ### 
A PostgreSQL instance that has multiple heavy-hitting, DML applications connected to it can have CPU load problems due to the fact that we are stacking up or accumulating the concurrent, active transactions of multiple applications. A general rule in PostgreSQL is that as the number of active, concurrent transactions (pg_stat_activity.state = 'active') exceeds 2 times the number of CPUs, we begin to experience CPU load saturation. This would be expected with multiple, heavy-hitting applications working against the same PostgreSQL Instance.

### Memory Contention ### 
With multiple, separate, heavy-hitting, DML applications hitting the same PostgreSQL instance, we start to see inherent problems when unrelated SQL workloads (separate databases, schemas, and tables) compete for the same memory resources. Normally with a single application, one thing good about it is that a lot of the disk to memory activity is with the same heavily used tables. So you usually get your 95% to 99% cache hit ratio. But when multiple, separate SQL Workloads are at work within a single PostgreSQL instance with their own set of tables, you may begin to see contention for memory-resident pages between the separate SQL workloads. In that case you have to make sure you have enough OS memory and shared_buffers memory to handle the surge when multiple SQL workloads compete for the same paging resources. Anticipating different degrees of load activity at any one point in time between the competing SQL workloads makes tuning shared buffers much harder and perhaps impossible to tune for both at the same time without adding significantly more reserved memory to shared_buffers even though it may not need it all most of the time.

### Transactions ###  
While the first statement after a COMMIT starts a new multi-statement transaction in Oracle RDBMS, Postgres operates in autocommit mode. Every piece of code doing some DML that is not to be committed immediately must start a transaction with a BEGIN statement. ROLLBACK and COMMIT have the same semantic meaning in both systems; also SAVEPOINTS mean the same. Postgres knows all the isolation levels Oracle knows (and a few more). In most cases the default isolation level of Postgres (Read Committed) will be sufficient.
