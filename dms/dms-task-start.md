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
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-initial-copy.png)

### 스키마 매핑룰 ###
![task list](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-mapping-rule.png)



### 4. 마이그레이션 사전 평가하기 ###

DMS 동작시 문제가 될 만한 사항을 사전에 체크해서 리포트 형식으로 보여준다. 리포트를 출력할 S3버킷 생성이 필요하고, DMS 서비스가 S3 에 결과값을 기록하기 때문에 S3에 접근 가능한 DMS 서비스 롤 생성이 필요한데,
해당 권한을 tf_dms_service_role 라는 이름을 테라폼에 의해 사전에 만들어져 있는 롤을 사용하면 된다. 

*사전평가 실행하는 화면.

* 결과화면
![assessment](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-premig-assessment.png)

