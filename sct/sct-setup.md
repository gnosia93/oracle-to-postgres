## SCT 설치 ##

### 소트웨어 다운로드 ###

* https://docs.aws.amazon.com/ko_kr/SchemaConversionTool/latest/userguide/CHAP_Installing.html 로 방문하여 macOS 용 파일을 다운로드 받은 후, 로컬 PC 에 설치합니다.

![download](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-download.png)


* 오라클 및 postgresql 용 JDBC 드라이버를 로컬 PC로 다운로드 받습니다.

  - https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/ojdbc8.jar
  - https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/postgresql-42.2.18.jar


### JDBC 경로 설정하기 ###

SCT 는 JDBC 를 이용하여 데이터베이스 서버에 접근합니다. 본 튜토리얼에서는 소스 데이터베이스로 오라클, 타겟 데이터베이스로 postgresql 을 사용할 예정입니다. 

SCT 를 실행한 후, 상단 Settings 메뉴밑에 Global Settings를 선택합니다. 
![setting](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-jdbc-setting.png)

아래 화면에 보이는 것처럼 좌측 [드라이버] 메뉴를 선택한 후, 각 데이터베이스에 맞는 JDBC 드라이버 경로를 설정합니다. 
![setting](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-jdbc-driver.png)


### 프로젝트 생성하기 ###

File 메뉴에서 New project 를 선택합니다. 
![new-project](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-new-create.png)

프로젝트 명을 tf_oracle_to_postgres 로 입력하고 소스는 오라클, 타켓은 postgres RDS 를 선택합니다. 
![project-info](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-new-project.png)

상단 메뉴에 [Connect to Oracle] 을 클릭한 후, 오라클 연결을 위한 설정 정보를 입력합니다. Type 을 Service Name 으로 변경한 후, Server name 은 오라클 데이터베이스의 공인 IP를 넣고, service name으로 pdb1 을 입력합니다. user name 은 system 이고, password 는 manager 입니다.
![oracle-connect](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-oracle-connect.png)

postgres 역시 오라클과 동일한 과정을 거치게 됩니다. 상단 메뉴에 [Connect to Amazon RDS for PostgreSQL] 을 선택한 후, 각 필드에 해당하는 정보를 입력합니다.
shop 유저의 패스워드는 shop 입니다. 
![postgres-connect](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-postgres-connect.png)

오라클 및 postgresql 이 제대로 연결되는지 확인합니다. 
![sct-result](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-connect-result.png)
