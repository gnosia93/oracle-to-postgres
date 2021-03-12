PostgreSQL 은 ARM 아키텍처를 지원한다. 아마존 EC2 인스턴스를 아래와 같이 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보이며, Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 11.5 이다.
프로덕션 보다는 테스트나 스테이징 용도로 사용하는 것이 적합해 보인다.

### PostgreSQL 설치하기(aarch64) ###
```
$ sudo amazon-linux-extras list | grep post
  4  postgresql9.6            available    [ =9.6.8  =stable ]
  5  postgresql10             available    [ =10  =stable ]
 34  postgresql11             available    [ =11  =stable ]

$ sudo amazon-linux-extras install postgresql11 epel -y

$ sudo yum install postgresql-server postgresql-contrib postgresql-devel -y

$ postgres --version
postgres (PostgreSQL) 11.5

```
