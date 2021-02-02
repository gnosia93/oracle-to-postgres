## 오브젝트 변환하기 ##

### 오브젝트 매핑 (Oracle to Postgresql) ###

* 데이터 타입 매핑 

  SCT 의해 자동 매핑되는 타입 변환 정보는 다음과 같습니다. 
```
number        ---> double precision
number(n)     ---> numeric(n, 0)             n 의 범위의 1 ~ 39
number(p, s)  ---> numeric(p, s)
float         ---> double precision
char(n)       ---> character(n)              n 의 범위는 1 ~ 2000
varchar2(n)   ---> character varying(n)      n 의 범위는 1 ~ 4000
date          ---> timestamp(0)
timestamp     ---> timestamp(6)
nchar(n)      ---> character(n)
nvarchar2(n)  ---> character varying(n)
blob          ---> bytea
clob          ---> text
long          ---> text
bfile         ---> 지원하지 않음
```

* 코드 오브젝트 매핑

  postgresql는 시퀀스, 뷰, 머티리얼라이즈 뷰, 함수, 프로시저, 트리거와 같은 코드성 오브젝트는 지원되나, 오라클의 패키지 및 Synonym 은 지원하지 않습니다.
  원본 데이터베이스인 오라클 데이터베이스에서 패키지를 사용하고 있고 해당 패키지가 이관 대상인 경우는 postgresql 의 namespace 에 해당하는 스키마로 매핑하도록 합니다.  


### 리포트 출력하기 ###

오라클의 오브젝트를 postgresql 로 변환하기 전에 리포트 생성 기능을 이용하여 매핑시 발생하는 오류를 사전에 확인할 수 있습니다.    
아래와 같이 오라클의 SHOP 스키마를 선택하고 팝업 메뉴에서 create report 를 선택합니다.  

[리포트 만들기]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-create-report.png)

[리포트 결과]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-report.png)

수정 또는 확인이 필요한 액션 아이템을 보여준고 있다. 주로 프로시저나 함수, 트리거와 같은 코드성 오브젝트에서 발생한다. 

[액션 아이템]
![action item](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-action-item.png)


### 오브젝트 변환 / 적용하기 ###

