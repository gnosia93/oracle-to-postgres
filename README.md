# Oracle to PostgreSQL Migration #

*Definitive guide from oracle to postgresql migration*

이 튜토리얼은 AWS DMS 서비스를 이용한 oracle to PostgreSQL 마이그레이션 전체 과정에 대한 이해를 돕기 위해 만들어 졌습니다. 본 튜토리얼은 여러분이 사용하는 클라리언트 PC 가 Mac OS 임 가정하고 작성되었으며, 테스트에 필요한 인프라의 경우 테라폼 스크립트를 이용하여 빌드합니다.
테라폼과 관련 정보는 https://www.terraform.io/ 에서 확인할 수 있고, 워크샵에서는 테라폼에 대한 내용은 다루지 않습니다.  
이문서는 AWS 클라우드와 오라클 데이터베이스에 대한 사전 경험 있다는 가정하에 작성되었으며, postgresql 의 경우 사전 지식이 없더라도 마이그레이션 전반에 걸친 사항에 대해 배울 수 있습니다. 

### PostgreSQL 운영 안정성 및 보안 ###

PostgreSQL은 수년에 걸쳐 반복적으로 입증 된 견고한 데이터베이스입니다. 은행, 정부, 국방, 의학 및 자동차 산업과 같은 중요한 환경에서 채택되었습니다. 다양한 방식의 인증과 pgaudit 을 이용한 감사로그, 3rd party 제품을 통한 Data Redation(Masking) 기능 및 데이터베이스 암호화 기능을 지원합니다.


## 아키텍처 ##

![architecture](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/oracle-to-postgres-architecture.png)

* 네트워크는 별도로 생성하지 않으며 계정별로 기본 제공되는 VPC 와 Public 서브넷을 활용합니다. 

* 마이그레이션 테스트를 위해 오라클, postgres, DMS 로 구성된 테스트 세트는 11xe 용과 19c 용으로 2세트로 구성되며, 테라폼에 의해 빌드됩니다. (아키텍처 다이어그램에는 19c만 표시)

* 오라클 11g 는 우분투, 19c 는 레드헷 8 버전의 EC2 인스턴스에 설치되며, postgres 의 경우 아마존 리눅스2에 설치됩니다. 

* 오라클 12C 부터는 CDB / PDB 아키텍처를 채용하고 있는데, Oracle Log Miner의 경우 PDB를 지원하지 않는 관계로 19C 의 경우 binary reader 방식으로 데이터를 복제하고, 11g의 경우 Log Miner 방식을 사용합니다.

* 트랜잭션 로그 전체를 DMS 로 전달하는 binary reader 방식에 비해, Oracle Log Miner 복제 방식은 원본 데이터베이스인 오라클 데이터베이스 CPU 를 좀 더 많이 사용하게 됩니다. 이는 원본 데이터베이스에서 복제 설정시 구성된 복제 항목에 따라 필터링을 먼저 수행한 후, DMS 로 해당 로그 데이터만 카피하는 구조로 되어 있기 때문이고, 오라클 로그 마이너는 원본 DB 의 변경이 많은 경우, 원본 데이터베이스의 성능에 영향을 주게 됩니다. 

* 샘플 스키마 및 초기 데이터 로딩 작업은 tf_loadgen EC2 인스턴스가 수행하고, 샘플 스키마 빌드는 sqlplus 와 shell script 로 구현되어 있으며, 초기 데이터 로딩은 python 으로 구현된 pyoracle 이라는 프로그램을 사용하게 됩니다. 

* 통상적으로 onprem의 오라클 데이터베이스를 AWS로 이전시 마이그레이션을 위한 네트워크는 VPN(1.25Gbps/s) 또는 DX(Max 40Gbps/s) 를 사용하게 되는데, 허용 가능한 서비스 다운타임에 따라 네트워크의 종류와 bandwidth 를 선택하게 됩니다. 마이그레이션을 위한 네트워크 아키텍처는 초기 데이터 로딩량과 변경 데이터량(ongoing 데이터 적재량)을 고려하여 설계하여야 합니다. 


## 실습 ##

### 1. 사전 준비 ###

- [PC 환경설정](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/pc-software.md) 

- [AWS 억세스 키 설정](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/aws-access-key.md)  


### 2. 인프라 빌드 ###

- [테라폼으로 인프라 구성하기](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/infra-build.md)


### 3. 복제를 위한 원본/타켓 DB 설정 ##

- [오라클 설정](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/oracle-prepare.md)

- [postgresql 설정](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/postgres-conf.md)



### 4. 샘플 데이터 로딩하기 ###

- [스키마 생성하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/init-schema.md)

- [샘플 데이터 빌드하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/init-data.md)


### 5. 스키마 변환하기 (/w SCT) ###

* [SCT 설치하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/sct-setup.md)

* [오브젝트 변환하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/sct-convert.md)


### 6. 데이터 복제하기 (/w DMS) ###

* [DMS 설정하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-settings.md)

* [DMS 태스크 실행하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-task-start.md)

* [마이그레이션 모니터링하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-monitoring.md)


### 7. PostgreSQL 성능 진단 및 테스트 ###

* [JMeter를 활용한 PostgreSQL 성능 테스트](https://github.com/gnosia93/postgres-terraform/blob/main/performance/jmeter.md)

* [슬로우 쿼리 확인하기](https://github.com/gnosia93/postgres-terraform/blob/main/performance/slow-query.md)

* [성능 진단/평가](https://github.com/gnosia93/postgres-terraform/blob/main/performance/performance-assessement.md)



## Appendix ##

* [소스 시스템 진단 / 타켓 시스템 사이징](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-sizing.md)

* [어플리케이션 변환 가이드(SQL/프로시저 변환가이드)](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/app-mig-guide.md)

* [어드민 가이드](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/admin-guide.md) / [개발자 가이드](https://www.tutorialspoint.com/postgresql/index.htm)

* [RDS Performance on Amazon Graviton2](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-arm.md)



## Revision History 

- 2021.2.01 draft released 
- 2021.3.16 postgre performance on AWS graviton2 added
- 2021.8.06 first released

