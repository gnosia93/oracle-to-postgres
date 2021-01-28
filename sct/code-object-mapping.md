DMS는 스키마 정보중 테이블, 제약조건 및 PK 인덱스에 대한 이관만을 지원한다. 시퀀스, 트리거, 프리시저와 같은 코드성 오브젝트에 대한 이관은 SCT 를 이용하여 별도로 진행해야 한다. 

## 시퀀스 ##

아래는 원본 데이터베이스인 오라클 데이터베이스 존재하는 시퀀스 정보를 나열한 것이다. postgresql 역시 시퀀스를 지원하므로, SCT 의 변환기능을 이용하여 시퀀스를 생성한다. 

```
SQL> col sequence_name format a30
SQL> select sequence_name, min_value, max_value, increment_by, cache_size, last_number 
     from dba_sequences where sequence_owner = 'SHOP';

SEQUENCE_NAME			MIN_VALUE  MAX_VALUE INCREMENT_BY CACHE_SIZE LAST_NUMBER
------------------------------ ---------- ---------- ------------ ---------- -----------
SEQ_COMMENT_COMMENT_ID			1 1.0000E+28		1	  20	  511420
SEQ_ORDER_ORDER_ID			1 1.0000E+28		1	  20	51117857
SEQ_PRODUCT_PRODUCT_ID			1 1.0000E+28		1	  20	    2001
```


## 뷰 ##


## 머티리얼 라이즈 뷰 ##


## Synonym ##

postgresql 는 synonym 을 지원하지 않는다.


## 프로시저 ##



## 함수 ##



## 패키지 ##

패키지 역시 지원하지 않으므로, 스키마 기능을 이용하여 프로시저와 함수를 그룹핑한다. 



