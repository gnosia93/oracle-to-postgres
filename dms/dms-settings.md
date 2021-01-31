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

AWS DMS 콘솔에 로그인하여 테라폼에 의해 생성된 리플리케이션 인스턴스와 엔드포인트를 아래와 같이 확인합니다. 리플리케이션 인스턴스를 2대 엔드포인트는 4개가 생성되어져 있어야 합니다. 

[리플리케이션 인스턴스]
![rep-instance](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-replication-inst.png)

[엔드포인트]
![rep-endpoint](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-ep.png)


### 엔드포인트 접속 테스트 ###

마이그레이션 태스크를 설정하기 전에 엔드포인트에 대한 접속 테스트는 필수이며, 접속 테스트에서 오류가 발생되는 경우 태스크 설정이 불능합니다. 19용 오라클 및 postgresql 에 대한 엔드포인트에 대한 접속 테스트를 진행합니다. 

[테스트 경로]
* DMS > Endpoints > tf-dms-19c-ep-oracle > Connections 탭 > [Test Connections] 버튼클릭 > Replication Instance tf-dms-19c 선택 > [Run Test] 버튼클릭
* DMS > Endpoints > tf-dms-19c-ep-postgres > Connections 탭 > [Test Connections] 버튼클릭 > Replication Instance 선택 > [Run Test] 버튼클릭

[오라클 테스트 결과]
![oracle test](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-test-oracle.png)

[postgres 테스트 결과]
![post test](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-test-postgres.png)


### 마이그레이션 태스크 설정 ###

마이그레이션 태스크 설정은 3단계로 구성되는데 태스크 설정과 셋팅 그리고 매핑이다. 본 워크샵에서 사용하는 오라클의 원본 테이블은 다양한 형태의 데이터 타입으로 구성되어져 있는데
상품(TB_PRODUCT) 테이블의 경우 상품 이미지를 저장하는 BLOB 및 상품 본문 HTML을 저장하기 위해 CLOB 칼럼 역시 가지고 있습니다. 

테이블 매핑과 관련해서 오라클의 경우 태이블, 칼럼과 같은 오브젝트 명칭에 대소문자를 가리지 않은 것에 반해, postgresql 의 경우 명시적으로 Quote를 사용하여 테이블 또는 칼럼을 만드는 경우 대소문자를
구분합니다. SCT 를 사용하지 않고 DMS 만을 사용하여 매핑을 설정하는 경우, DMS 가 자동으로 칼럼 데이터 타입을 인지하여 타켓 데이터베이스에 테이블을 만들게 되는데, 생성시 Quote("") 를
사용하기 때문에 postgres 데이베이스에는 대문자로 인식되어 생성되게 됩니다. 이렇게 생성되게 되면 테이블 및 칼럼을 접그할때 Quote("") 를 항상 사용해야 하는 불편함임 존재하게 됩니다. 

마이그레이션 태스크 매핑 설정시 스키마, 테이블 및 칼럼 명칭에 대한 lower case 매핑룰을 명시적으로 설정해서 이러한 문제를 사전에 방지하는 것이 좋습니다. lower case 룰을 설정하지 않는 경우
postgresql 클라이언트를 사용하여 테이블에 대한 데이터 입력 및 조회시 쌍따옴표를 이용하여 오브젝트 명칭을 감싸줘야 제대로 SQL 이 에러없이 동작하게 됩니다. 

아래의 내용을 참고하여 19c용 마이그레이션 태스크를 생성합니다. (11xe 역시 태스크를 만드는 순서는 19c와 동일합니다)

[Create Task] 버튼을 클릭합니다.
![create task](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-task-create.png)

tf-task-19c 태스크 이름으로 입력하고, tf-dms-19c를 리플리케이션 인스턴스로 설정한 후, 엔드포인트를 그림처럼 설정하고, Migration existing data and relicate ongoing changes 를 마이그레이션 타입으로 선택합니다. 
![task-config](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-task-config.png)

Full LOB mode 를 선택하고, Enable validation, Enable CloudWatch logs를 선택합니다. 
![task-setting](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-task-setting.png)

Table Mapping 설정시 SHOP 은 소문자가 아닌 대문자로 표기해야 합니다. 소문자로 표기하는 경우 테이블 복제가 이뤄지지 않고 복제 대상이 없다는 에러가 발생하게 되므로 주의가 필요합니다.  

![task-mapping1](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-task-table-mapping.png)

변형룰 설정시 스키마, 테이블, 칼럼을 타켓으로 해서 각각 룰을 만들어 적용해야 합니다. 스키마 명칭은 SHOP 으로 입력하고, Action 값은 lowercase 로 입력하시기 바랍니다.
설정이 완료된 경우 [createe task] 버튼을 눌려 태스크를 생성합니다. 
![task-mapping2](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-tabsk-trans-rule.png)


![task-mapping2](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-tabsk-create-button.png)
![task-mapping2](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/mig-tabsk-result.png)

### 생성된 마이그레이션 태스크 조회 ###

## 오류 메시지 해결 ##
