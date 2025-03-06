
### pg_upgrade --link ###
* 하드링크를 사용하여 업그레이드 하므로 수분안에 업그레이드가 가능하다.
* inplace 업그레이드시 카탈로그 정보를 변경한다.
* 하드링크는 파일시스템의 메타데이터에 정보를 저장하는 inode 를 공유한다.   
* pg_dump(all) 또는 logical replication (cdc) 이용하여 업그레이드 할 수도 있다. 
