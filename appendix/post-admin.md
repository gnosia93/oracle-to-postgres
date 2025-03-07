### [Architecture](https://www.youtube.com/watch?v=6f-TqM4HYPY&list=PLZwFtgKc35I_05Hr9e_3dsWpOCv9c7k2L&index=15) ###

* checkpoint - Synchronizing memory state and disk state
* postgres memory structure
   * shared memory
     * shared buffer 
     * wall buffer
     * clog buffer (tx buffer)
     * lock space 
   * local memory 

### WAL ###
* ACID
  * atomicity
  * consistency
  * isolation
    * uncommitted read
    * committed read
    * repeatable read
    * serializable - SERIALIZABLE is the strictest isolation level, and as the name suggests, it proceeds transactions sequentially
  * durability      


* $PG_DATA/pg_wal/
  * default size of file is 16MB (wal_segment_size)
  * pg_wal directory's default size is 1gb, when this directory size increase more than 1gb, existing file is overritten. (max_wal_size)
  * lsn => log sequence number / distincquish each tx records with lsn.

![](https://github.com/gnosia93/oracle-to-postgres/blob/main/appendix/images/pg-wal-2.png)

* https://pgbackrest.org/

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


### pg_vector extension ###
* 유클리디안 거리(L2 distance) - https://blog.naver.com/bsw2428/221388885007
* Cosine Similarity - https://wikidocs.net/24603
    * 문서를 구성하는 단어들의 벡터의 방향성을 우선으로 계산하기 때문에 문서의 길이에 영향을 받을 수 있는 유클리디안 방식보다 정확하다.
    * 예를들어 A, B, C 문서가 있고, A 와 B 가 유사한 문서이지만, B 가 상대적으로 A 보다 2배 정도의 분량이고, C 의 경우 A 와
      동일한 분량의 문서의 경우 A-C 의 유사도가 A-B 유사도 보다 높게 나오는 경우가 발생한다.  
* vector 내적 - https://blog.naver.com/sw4r/221939046286
  * 내적은 영어로 다양하게 불리는데 Inner product 라고도 하고, dot product, scalar product 라고도 불린다. 가끔은 projection product 라고도 불린다


