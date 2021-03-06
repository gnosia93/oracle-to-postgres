## 마이그레이션 모니터링 하기 ##

### 복제 인스턴스 모니터링 하기 ###

AWS DMS >> Replication Instnaces >> tf-dms-19c >> CloudWatch metrics 탭을 이용하여 복제 인스턴스의 CPU, Memroy, Swap 및 디스크 사용률과 같은 OS 메트릭 정보를 확인할 수 있다. 
![instnace](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-monitoring-instance.png)


### 마이그레이션 태스크 모니터링 하기 ###

클라우드 와치 기능을 활용하면 DMS 의 현재 상태와 성능을 모니터링 할 수 있다.
AWS DMS >> Database migration tasks >> task-19c-binr >> CloudWatch metrics 경로 화면에서 상단 콤보 박스에서 CDC 를 선택하면,
DMS 로 유입되는 변경량 및 각종 latency 정보를 확인할 수 있다. 
CDC 뿐만아니라, Full load, Validation 등과 같은 추가적으로 정보 역시 확인 가능하다. 
![cdc](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/dms-monitoring-cdc.png)



