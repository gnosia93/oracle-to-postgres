PostgreSQL 은 ARM 아키텍처를 지원한다. 아마존 EC2 인스턴스를 아래와 같이 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보이며, Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 9.2.24-1.amzn2.0.1 이다.
프로덕션 보다는 테스트나 스테이징 용도로 사용하는 것이 적합해 보인다.

### PostgreSQL 설치하기(aarch64) ###
```
[ec2-user@ip-172-31-43-151 ~]$ sudo yum install postgresql
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
Resolving Dependencies
--> Running transaction check
---> Package postgresql.aarch64 0:9.2.24-1.amzn2.0.1 will be installed
--> Processing Dependency: postgresql-libs(aarch-64) = 9.2.24-1.amzn2.0.1 for package: postgresql-9.2.24-1.amzn2.0.1.aarch64
--> Processing Dependency: libpq.so.5()(64bit) for package: postgresql-9.2.24-1.amzn2.0.1.aarch64
--> Running transaction check
---> Package postgresql-libs.aarch64 0:9.2.24-1.amzn2.0.1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================
 Package                                 Arch                            Version                                      Repository                          Size
===============================================================================================================================================================
Installing:
 postgresql                              aarch64                         9.2.24-1.amzn2.0.1                           amzn2-core                         3.0 M
Installing for dependencies:
 postgresql-libs                         aarch64                         9.2.24-1.amzn2.0.1                           amzn2-core                         232 k

Transaction Summary
===============================================================================================================================================================
Install  1 Package (+1 Dependent package)

Total download size: 3.3 M
Installed size: 17 M
Is this ok [y/d/N]: 
```
