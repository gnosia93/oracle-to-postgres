### WAL ###
![](https://github.com/gnosia93/oracle-to-postgres/blob/main/appendix/images/pg-wal-1.png)

* $PG_DATA/pg_wal/
  * default size of file is 16MB (wal_segment_size)
  * pg_wal directory's default size is 1gb, when this directory size increase more than 1gb, existing file is overritten. (max_wal_size)
  * lsn => log sequence number / distincquish each tx records with lsn.

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
