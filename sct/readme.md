본 튜토리얼에서 SCT 를 사용하여 사전 스키마 매핑 작업을 수행하지 않고, DMS 자체의 스키마 생성 및 변환 기능만을 이용하여 데이터를 이관하였다.
이관이후, 자동으로 생성된 테이블에 대한 메타 정보를 확인하기 위해서는 pgadmin 과 같은 클라이언트 툴을 사용하여거나, postgresql 의 카탈로그를 이용하여
원하는 정보를 조회할 수 있다.

### 1. pgadmin 을 이용한 정보 조회 ###



### 2. postgresql 카탈로그 이용하기 ###


마이그레이션 작업 수행이전에 타켓 스키마를 생성하고자 하는 경우 AWS SCT 를 이용하여 스키마 매핑 및 원하는 형태의 스키마로 수정할 수 있으며, 이와 관련된 내용은 AWS 메뉴얼(https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) 을 참고하길 바란다.
