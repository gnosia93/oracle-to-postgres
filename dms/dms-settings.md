## DMS 설정하기 ##

DMS 는 AWS 가 제공하는 CDC 방식의 데이터 복제 전용서비스로 동종 또는 이기종 데이터베이스 간 또는 S3 및 다이나모DB 와 같은 저장 스토리지로의 데이터 복제 기능을 지원하는 서비스로 아래와 같이 3가지의 요소로 구성이 되어 있습니다.

* 리플리케이션 인스턴스
* 엔드포인트
* 마이그레이션 태스크

리플리케이션 인스턴스는 AWS 클라우드 상에 생성되는 복제 전용 서버로 원본 데이터베이스의 트랜잭션 로그를 읽어서 타켓 데이터베이스 적용하는 역할을 하는 서버입니다.
원본 데이터베이스의 트랜잭션 량과 복제시 발생할 수 있는 지연시간을 최소화 하기 위해 인스턴스의 크기와 EBS 볼륨의 크기를 결정하게 되는데, EBS 볼륨의 기본값은 50GB 입니다.   

엔드포인트의 경우 소스 및 타켓 데이터베이스에 접속하기 위한 설정값을 모아놓은 오브젝트로 오라클의 경우 로그 마이너 방식과 바이너리 리더 방식을 지원하고 있습니다.
본 워크샵에서는 오라클 19c 용으로 바이너리 리더 엔드포인트를 1개를, 11xe 용으로 로그 마이너 방식의 엔들포인트를 1개 만들고, postgres 용 엔드포인트는 19c, 11xe 용으로 각각 1개씩 만들어지게 됩니다.
엔드 포인트의 설정 항목중 extra_connection_attributes 의 값이 "useLogminerReader=N; useBfile=Y" 설정되면 바이너리로그 모드이며, 값이 없는 경우 로그 마이너 모드를 의미하게 됩니다. 

마이그레이션 태스크의 경우 실제 마이그레이션시 적용되는 룰값을 설정하는 오브젝트로 복제의 대상이 되는 스키마, 스키마 변경룰, LOB 칼럼 복제와 관련된 설정등을 저장하고 있습니다. 
DMS에 대한 보다 자세한 내용은 https://docs.aws.amazon.com/ko_kr/dms/latest/userguide/Welcome.html 에서 확인하실 수 있습니다. 

![architecture](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-architecture.png)

본 워크샵에서는 테라폼을 이용하여 리플리케이션 인스턴스와 오라클 및 postgres용 엔드포인트를 생성하는데, 11xe 및 19c 용으로 각각 1세트씩 만들어지게 됩니다. 
마이그레이션 태스크의 경우 테라폼이 아닌, AWS DMS 콘솔로 로그인하여 직접 한번 만들어 볼 예정입니다. 

### 테라폼이 생성한 리소스 확인 ###

DMS 인스턴스와 소스 및 타켓 데이터베이스에 대한 엔드포인트는 테라폼에 의해 자동으로 생성된다. 아래는 생성된 DMS 인스턴스와 엔드포인트에 대한 결과 화면이다. 

![rep-instance](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-replication-instnace.png)

![rep-endpoint](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-endpoint.png)


#### 2 엔드포인트 접속 테스트 ####

자동으로 생성된 엔드포인트에 대한 접속 테스트를 아래와 같이 실행한다. 

![endpoint test](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-endpint-test.png)


#### 3 마이그레이션 태스크 설정 ####

마이그레이션 태스크 설정은 3단계로 구성되는데 태스크 설정과 셋팅 그리고 매핑이다. 본 워크샵에서 사용하는 오라클의 원본 테이블은 다양한 형태의 데이터 타입으로 구성되어져 있는데
품(TB_PRODUCT) 테이블의 경우 상품 이미지를 저장하는 BLOB 및 상품 본문 HTML을 저장하기 위해 CLOB 칼럼을 사용하고 있다.

테이블 매핑과 관련해서 오라클의 경우 태이블, 칼럼과 같은 스키마의 명칭에 대소문자를 가리지 않은 것에 반해, postgresql 의 경우 명시적으로 Quote를 사용하여 테이블 또는 칼럼을 만드는 경우 대소문자를
구분하게 된다. SCT 를 사용하지 않고 DMS 만을 사용하여 매핑을 설정하는 경우, DMS 가 자동으로 데이터 타입을 인지하여 스키마를 만들게 되는데, 스키마 생성시 Quote("") 를
사용하기 때문에 postgres 입장에서는 대소문자를 구분짓게 되는 것이다.

마이그레이션 태스트 매핑 설정시 스키마, 테이블 및 칼럼 명칭에 대헛 lower case 매핑룰을 설정해서 이러한 문제를 사전에 방지해야 한다. lower case 룰을 설정하지 않는 경우
postgresql 클라이언트를 사용하여 테이블에 대한 데이터 입력 및 조회시 쌍따옴표를 이용하여 오브젝트 명칭을 감싸줘야 제대로 SQL 이 에러없이 동작하게 된다. 

아래의 내용을 참고하여 마이그레이션 태스크를 설정한다. 이때 한가지 주의 할점은 DMS 의 경우 대소문자를 구별하기 때문에 오라클의 SHOP 스키마의 경우 소문자가 아닌 대문자로 

표기해야 한다. 소문자로 표기하는 경우 테이블 복제가 이뤄지지 않고 복제 대상이 없다는 에러가 발생한다. 

![task-configuration](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-configuration.png)

![task-setting](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-setting.png)

![task-mapping](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-table-mapping.png)



- binary reader

- log miner
