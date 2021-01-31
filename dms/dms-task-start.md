## DMS 마이그레이션 실행하기 ##

태스크가 에러없이 생성되면 마이그레이션 작업은 자동으로 실행됩니다. 이니셜 카피를 완료 한후, ongoing 모드로 지속적으로 원본 데이터베이스의 변경로그를 읽어서 타켓 데이터베이스에 적용하게 됩니다. 
원본 데이터베이스의 볼륨에 따라서 이니셜 카피 시간이 결정되고, cloud watch 의 메트릭을 통해 동작 상태를 확인하실 수 있습니다. 

### 마이그레이션 태스크 리스트 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-list.png)

### 태스크 오버뷰 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-overview.png)

### 태스크 로그 ###
![task cloudwatch logs](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-cloudwatch.png)

### 테이블 통계 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-table-stat.png)

### 이니셜 카피 확인 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-initiial-copy.png)

### 스키마 매핑룰 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-mapping-rule.png)



## 마이그레이션 사전 평가하기 ##

마이그레이션 태스크를 만들때, 사전 평가를 통해서 설정과 관련된 문제점을 한눈에 파악하실 수 있습니다. 
DMS 동작시 문제가 될 만한 사항을 사전에 자동으로 체크해서 리포트 형식으로 보여주는데 리포트 결과를 출력할 S3버킷 필요하고, 이와관련하여 DMS 역시 해당 S3 버킷에 대한 Write 권한을 가지고 있어야 합니다.(서비스롤 생성 필요) 
본 워크샵에서는 테라폼이 tf_dms_service_role 라는 이름의 서비스 권한이 만들어 줍니다. 리포트 생성시 해당 권한을 사용하면 사전 평가 리포트를 만들어 낼 수 있습니다. 

### 평가 생성하기 ###
![assessment](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-assessment.png)

### 평가 설정하기 ###
![assessment](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-assessment-conf.png)

### 평가 조회하기 ###
![assessment](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-premig-assessment.png)

