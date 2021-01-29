# Oracle to Postgres Migration Workshop #

이 튜토리얼은 AWS DMS 서비스를 이용한 oracle to Postgres 마이그레이션 전체 과정에 대한 이해를 돕기 위해 만들어 졌습니다.   
본 튜토리얼은 여러분이 사용하는 클라리언트 PC 가 Mac OS 임 가정하고 작성되었으며, 테스트에 필요한 인프라의 경우 테라폼 스크립트를 이용하여 자동빌드하며,
반복적이고 빠른 테스트를 위해 AWS Console 화면을 통한 조작은 최소화 하였습니다.  
테라폼과 관련 정보는 https://www.terraform.io/ 에서 확인할 수 있고, 본문에서는 테라폼 사용법에 대한 내용은 다루지 않습니다.  
기존에 AWS 콘솔과 오라클 데이터베이스에 대한 사전 경험 있다는 가정하에 작성되었으며, postgresql 의 경우 사전 지식이 없더라도 마이그레이션과 관련된 정보를 습득할 수 있습니다. 

## 마이그레이션 프로세스 ##

- 현행 시스템 평가
- 타켓 시스템 사이징
- 스키마 변경 설계
- 데이터 이관 테스트 및 이관 성능 튜닝 
- 어플리케이션 검증 (기능 및 성능검증)
- 데이터 이행 / 서비스 오픈
- 성능 모니터링 / 튜닝

## 실습 아키텍처 ##

![architecture](https://github.com/gnosia93/postgres-terraform/blob/main/images/oracle-to-postgres-architecture.png)

* EC2 서버들이 배치되는 네트워크는 별도로 생성하지 않으며 계정별로 제공되는 기본 VPC 및 해당 VPC의 public 서브넷을 사용합니다. 

* 마이그레이션 테스트를 위해 오라클, postgres, DMS 로 구성된 테스트 세트는 11xe 용과 19c 용으로 2세트로 구성되며, 테라폼에 의해 빌드됩니다. (아키텍처 다이어그램에는 19c만 표시)

* 오라클 12C 부터는 CDB / PDB 아키텍처를 채용하고 있는데, Oracle Log Miner의 경우 PDB를 지원하지 않는 관계로 19C 의 경우 binary reader 방식으로 데이터를 복제하고, 11g의 경우 Log Miner 방식을 사용합니다.

* 트랜잭션 로그 전체를 DMS 로 전달하는 binary reader 방식에 비해, Oracle Log Miner 복제 방식은 원본 데이터베이스인 오라클 데이터베이스 CPU 를 좀 더 많이 사용하게 됩니다. 이는 원본 데이터베이스에서 복제 설정시 구성된 복제 항목에 따라 필터링을 먼저 수행한 후, DMS 로 해당 로그 데이터만 카피하는 구조로 되어 있기 때문이고, 오라클 로그 마이너는 원본 DB 의 변경이 많은 경우, 원본 데이터베이스의 성능에 영향을 주게 됩니다. 

* 샘플 스키마 및 초기 데이터 로딩 작업은 tf_loadgen EC2 인스턴스가 수행하고, 샘플 스키마 빌드는 sqlplus 와 shell script 로 구현되어 있으며, 초기 데이터 로딩은 python 으로 구현된 pyoracle 이라는 프로그램을 사용하게 됩니다. 

* Network bandwidth 는 마이그레이션 성능에 영향은 주는 주요 요소중에 하나 입니다. 이번 워크샵에서는 원본 및 타켓 데이터베이스가 동일한 VPC 에 존재하므로, 네트웍에 의한 성능 저하 이슈는 다루지 않습니다. 

* 통상적으로 onprem의 오라클 데이터베이스를 AWS로 이전시 마이그레이션을 위한 네트워크는 VPN(1.2Gbps/s) 또는 DX(Max 40Gbps/s) 를 사용하게 되는데, 허용 가능한 서비스 다운타임에 따라 네트워크의 종류와 bandwidth 를 선택하게 됩니다. 마이그레이션을 위한 네트워크 아키텍처는 초기 데이터 로딩량과 변경 데이터량(ongoing 데이터 적재량)을 고려하여 설계하여야 합니다. 


## 마이그레이션 실습 ##

### 1. 사전 준비 ###

- [PC 환경 설정](https://github.com/gnosia93/postgres-terraform/blob/main/pc/readme.md) 

- [workshop 체크아웃]()

- [aws 로그인키 설정]()  


### 2. 인프라 빌드 ###

인프라 구성요소는 소스 데이터베이스인 오라클과 타켓 데이터베이스인 postgresql, 데이터 복제시 사용할 DMS 인스턴스 및 초기 데이터 로딩에 사용되는 EC2 인스턴스로 구성되어 있다.  
오라클 설치, OS 파리미터 설정, 네트워크 설정 등과 같은 기본적인 설정은 모두 자동화 되어 있기 때문에, DMS 와 postgresql 에 대한 이해도를 높일 수...

오라클의 경우 약 30분 정도의 시간이 걸린다. 

```
var.tf 수정 (내아이피를 확인한 후)
$ terraform apply -auto-approve
```

### 3. 복제를 위한 원본/타켓 DB 설정 ##

- [오라클 설정](https://github.com/gnosia93/postgres-terraform/blob/main/oracle/oracle-prepare.md)

- [postgresql 설정](https://github.com/gnosia93/postgres-terraform/blob/main/postgres/postgres-conf.md)



### 4. 샘플 데이터 로딩하기 ###

- [스키마 생성하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/init-schema.md)

- [데이터 생성하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/init-data.md)


### 5. 스키마 변환(/w SCT) ###

* [데이터 오브젝트 변환](https://github.com/gnosia93/postgres-terraform/blob/main/sct/data-object-mapping.md)

* [코드 오브젝트 변환](https://github.com/gnosia93/postgres-terraform/blob/main/sct/code-object-mapping.md)


### 6. 데이터 복제하기(/w DMS) ###

* [DMS 설정하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-settings.md)

* [DMS 태스크 실행하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-task-start.md)

* [DMS 동작 모니터링하기](https://github.com/gnosia93/postgres-terraform/blob/main/dms/dms-monitoring.md)


### 7. 성능 테스트 및 진단 ###

* [postgres 스트레스 테스트](https://github.com/gnosia93/postgres-terraform/blob/main/performance/jmeter.md)

* performance assessment

* identifiy slow query / sql tunning


## Appendix ##

* 어플리케이션 변환 가이드
* [postgresql 어드민 가이드](https://github.com/gnosia93/postgres-terraform/blob/main/admin/readme.md)




## Revision History 

- 2021.2.1 V0.1 first draft released 







