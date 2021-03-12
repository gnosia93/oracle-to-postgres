PostgreSQL 은 ARM 아키텍처를 오래전 부터 지원하고 있다. 아마존 EC2 Graviton2 인스턴스를 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보인다. 

### Supported Version of Linux Distributions ###

* Unbutu 의 경우 - PostgreSQL 12 까지 지원

  https://www.postgresql.org/download/linux/ubuntu/

* CentOS 의 경우 - PostgreSQL 13 까지 지원

  https://www.postgresql.org/download/linux/redhat/
  
* Amazon Linux 2 의 경우 - PostgreSQL 11 까지 지원
   
  Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 11.5 이다.


### ARM EC2 생성하기 ###

화면덤프..
CLI 

### PostgreSQL 설치하기(aarch64) ###

* https://docs.aws.amazon.com/ko_kr/corretto/latest/corretto-11-ug/what-is-corretto-11.html
Amazon Corretto는 무료로 사용할 수 있는 Open Java Development Kit(OpenJDK)의 프로덕션용 멀티플랫폼 배포판입니다. Corretto에는 성능 향상과 보안 수정 사항을 비롯한 장기 지원이 함께 제공됩니다. Corretto는 Java SE 표준과 호환되는 것으로 인증되었으며, 여러 프로덕션 서비스용으로 Amazon에서 내부적으로 실행됩니다. Corretto를 사용하면 Amazon Linux 2, Windows, macOS 같은 운영 체제에서 Java 애플리케이션을 개발하고 실행할 수 있습니다.

```
$ uname -a
Linux ip-172-31-43-151.ap-northeast-2.compute.internal 4.14.219-164.354.amzn2.aarch64 #1 SMP Mon Feb 22 21:18:49 UTC 2021 aarch64 aarch64 aarch64 GNU/Linux

$ sudo yum install java-11-amazon-corretto

$ sudo amazon-linux-extras list | grep post
  4  postgresql9.6            available    [ =9.6.8  =stable ]
  5  postgresql10             available    [ =10  =stable ]
 34  postgresql11             available    [ =11  =stable ]

$ sudo amazon-linux-extras install postgresql11 epel -y

$ sudo yum install postgresql-server postgresql-contrib postgresql-devel -y

$ postgres --version
postgres (PostgreSQL) 11.5
```


### 성능테스트(pgbench) ###

* https://www.enterprisedb.com/blog/pgbench-performance-benchmark-postgresql-12-and-edb-advanced-server-12

* https://browndwarf.tistory.com/52

````
$ which pgbench
/usr/bin/pgbench

```


PostgreSQL ARM vs X86

PostgreSQL X86 vs Oracle 

* http://creedonlake.com/black-sails-bbx/e7c65b-postgresql-vs-oracle-performance-benchmark

