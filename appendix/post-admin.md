### [Architecture](https://www.youtube.com/watch?v=6f-TqM4HYPY&list=PLZwFtgKc35I_05Hr9e_3dsWpOCv9c7k2L&index=15) ###

* checkpoint - Synchronizing memory state and disk state
* postgres memory structure
   * shared memory
     * shared buffer 
     * wall buffer
     * clog buffer (tx buffer)
     * lock space 
   * local memory
* background process
   * postgres (master) -> fork backround process
   * background writer
   * wal writer
   * auto vaccume.
   * checkpoint  
* [pg_hba.conf](https://berasix.tistory.com/entry/PostgreSQL-%EC%84%A4%EC%B9%98%EC%99%80-%EC%9A%B4%EC%98%81-3-pghbaconf-%EC%84%A4%EC%A0%95%ED%95%98%EA%B8%B0)   

### WAL ###
* ACID
  * atomicity
  * consistency
  * [isolation](https://mangkyu.tistory.com/299)
    * uncommitted read
    * committed read
    * repeatable read
    * serializable - SERIALIZABLE is the strictest isolation level, and as the name suggests, it proceeds transactions sequentially (SERIALIZABLE은 가장 엄격한 격리 수준으로, 이름 그대로 트랜잭션을 순차적으로 진행시킨다)
  * durability      


* $PG_DATA/pg_wal/
  * default size of file is 16MB (wal_segment_size)
  * pg_wal directory's default size is 1gb, when this directory size increase more than 1gb, existing file is overritten. (max_wal_size)
  * lsn => log sequence number / distincquish each tx records with lsn.

![](https://github.com/gnosia93/oracle-to-postgres/blob/main/appendix/images/pg-wal-2.png)

* https://tmaxtibero.blog/4592/

### replication ###
![](https://github.com/gnosia93/oracle-to-postgres/blob/main/appendix/images/pg_replication.png)
* A replication slot is a PostgreSQL feature that ensures the master server keeps the WAL logs required by replicas even when they are disconnected from the master.
* pg_basebackup is used to take a base backup of a running PostgreSQL database cluster. The backup is taken without affecting other clients of the database, and can be used both for point-in-time recovery (see Section 25.3) and as the starting point for a log-shipping or streaming-replication standby server (see Section 26.2).
* In PostgreSQL, "LSN" stands for "Log Sequence Number," which is essentially a unique identifier that points to a specific location within the Write-Ahead Log (WAL), essentially marking the position where a transaction's changes were recorded; it acts as a pointer to track the chronological order of data modifications within the database system.
* replica instance has standby.signal file, it means this instance is replica. 


### [pg_upgrade --link](https://blog.ex-em.com/1746) ###
* 하드링크를 사용하여 업그레이드 하므로 수분안에 업그레이드가 가능하다.
* inplace 업그레이드시 카탈로그 정보를 변경한다.
* 하드링크는 파일시스템의 메타데이터에 정보를 저장하는 inode 를 공유한다.   
* pg_dump(all) 또는 logical replication (cdc) 이용하여 업그레이드 할 수도 있다. 

* [postgresql db version upgrade](https://www.google.co.kr/search?q=postgresql+db+version+upgrade&sca_esv=0aa6c026f1990de0&sxsrf=AHTn8zpIbfPQ-O9GoJqYygvxexp4q88j_Q%3A1741409756602&source=hp&ei=3M3LZ_DvIZ3F1e8P_YiUuAs&iflsig=ACkRmUkAAAAAZ8vb7ICDGP6mtQ0k8sq1jhWUNNBHQzYh&ved=0ahUKEwjwzcrv2PmLAxWdYvUHHX0EBbcQ4dUDCBs&uact=5&oq=postgresql+db+version+upgrade&gs_lp=Egdnd3Mtd2l6Ih1wb3N0Z3Jlc3FsIGRiIHZlcnNpb24gdXBncmFkZTIFECEYoAEyBRAhGKABSOBDUABYu0JwA3gAkAEAmAHTAaAB1RuqAQYxLjI4LjG4AQPIAQD4AQGYAiGgAsYcqAIBwgILEAAYgAQYsQMYgwHCAgQQABgDwgIREC4YgAQYsQMY0QMYgwEYxwHCAggQLhiABBixA8ICCxAuGIAEGLEDGIMBwgIFEAAYgATCAggQABiABBixA8ICBhCzARiFBMICDhAuGIAEGLEDGNEDGMcBwgIEEAAYHsICBhAAGAgYHsICBhAAGAUYHsICCBAAGAUYChgewgIEECEYFcICBxAhGKABGAqYAwPxBRH2-W69B066kgcGMy4yOS4xoAe6rQE&sclient=gws-wiz)


### backup & recovery ###

* https://github.com/ossc-db/pg_rman
* https://pgbackrest.org/

시간차가 있는 standby 복제서버를 둔다던가, 백업본을 사용해 특정시점으로 복구하는 방안이 있지만 flashback이나 temporal table 같은 기능은 제공되지 않음
* https://database.sarang.net/?criteria=pgsql


### pg_vector extension ###
* 유클리디안 거리(L2 distance) - https://blog.naver.com/bsw2428/221388885007
* Cosine Similarity - https://wikidocs.net/24603
    * 문서를 구성하는 단어들의 벡터의 방향성을 우선으로 계산하기 때문에 문서의 길이에 영향을 받을 수 있는 유클리디안 방식보다 정확하다.
    * 예를들어 A, B, C 문서가 있고, A 와 B 가 유사한 문서이지만, B 가 상대적으로 A 보다 2배 정도의 분량이고, C 의 경우 A 와
      동일한 분량의 문서의 경우 A-C 의 유사도가 A-B 유사도 보다 높게 나오는 경우가 발생한다.  
* vector 내적 - https://blog.naver.com/sw4r/221939046286
  * 내적은 영어로 다양하게 불리는데 Inner product 라고도 하고, dot product, scalar product 라고도 불린다. 가끔은 projection product 라고도 불린다


## misc ##

* [PostgreSQL 아카이브 백업과 특정시점 복구방법](https://mozi.tistory.com/560)

