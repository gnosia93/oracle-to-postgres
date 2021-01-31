## DMS 마이그레이션 실행하기 ##

태스




### 1. 태스크 오버뷰 ###

![overview](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-overview.png)


### 2. 테이블 복제 현황 관찰하기 ###

![table](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-table-stats.png)


### 3. 매핑룰 확인하기 ###

![mapping](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-mapping.png)


### 4. 마이그레이션 사전 평가하기 ###

DMS 동작시 문제가 될 만한 사항을 사전에 체크해서 리포트 형식으로 보여준다. 리포트를 출력할 S3버킷 생성이 필요하고, DMS 서비스가 S3 에 결과값을 기록하기 때문에 S3에 접근 가능한 DMS 서비스 롤 생성이 필요한데,
해당 권한을 tf_dms_service_role 라는 이름을 테라폼에 의해 사전에 만들어져 있는 롤을 사용하면 된다. 

*사전평가 실행하는 화면.


* 결과화면
![assessment](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/task-premig-assessment.png)

