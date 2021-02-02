## 오브젝트 변환하기 ##

### 오브젝트 매핑 (Oracle to Postgresql) ###

* 데이터 타입 매핑 

  SCT 의해 자동 매핑되는 타입 변환 정보는 다음과 같습니다. 
```
number        ---> double precision
number(n)     ---> numeric(n, 0)             n 의 범위의 1 ~ 39
number(p, s)  ---> numeric(p, s)
long          ---> text
float         ---> double precision
char(n)       ---> character(n)              n 의 범위는 1 ~ 2000
varchar2(n)   ---> character varying(n)      n 의 범위는 1 ~ 4000
date          ---> timestamp(0)
timestamp     ---> timestamp(6)
nchar(n)      ---> character(n)
nvarchar2(n)  ---> character varying(n)
bfile         ---> 지원하지 않음
```

* 코드 오브젝트 매핑

  일부 코드성 오브젝트의 경우 오라클에서만 지원됩니다. 
```

```




### 리포트 출력하기 ###

오라클의 오브젝트를 postgresql 로 변환하기 전에 리포트를 뽑아서 발생가능 한 오류에 대해 확인할 수 있습니다. 
아래와 같이 오라클의 SHOP 스키마를 선택하고 팝업 메뉴에서 create report 를 선택합니다.  

[리포트 만들기]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-create-report.png)

[리포트 결과]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-report.png)

수정 또는 확인이 필요한 액션 아이템을 보여준고 있다. 주로 프로시저나 함수, 트리거와 같은 코드성 오브젝트에서 발생한다. 

[액션 아이템]
![action item](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-action-item.png)


### 오브젝트 변환 / 적용하기 ###

