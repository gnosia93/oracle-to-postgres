## CPU/Memory/FileIO 성능 테스트 ##

- https://github.com/akopytov/sysbench
- https://wiki.gentoo.org/wiki/Sysbench#cite_note-1


### sysbench 설치 ###

- https://zenliu.medium.com/sysbench-1-1-installation-for-aws-ec2-instance-running-amazon-linux-a330b1cce7a7

```
[ec2-user@ip-172-31-28-94 ~]$ sudo yum -y install git gcc make automake libtool openssl-devel ncurses-compat-libs

[ec2-user@ip-172-31-28-94 ~]$ git clone https://github.com/akopytov/sysbench

[ec2-user@ip-172-31-28-94 ~]$ cd sysbench
[ec2-user@ip-172-31-28-94 sysbench]$ ./autogen.sh
[ec2-user@ip-172-31-28-94 sysbench]$ ./configure --without-mysql
[ec2-user@ip-172-31-28-94 sysbench]$ make; sudo make install

[ec2-user@ip-172-31-28-94 sysbench]$ sysbench --version
sysbench 1.1.0-bbee5d5
```

### CPU 성능 측정 ###

10만개의 소수를 계산하는 로직을 1만회 수행하는데 소요되는 시간을 계산한다. 즉 한번 실행시 10만개의 소수를 계산하는 함수를 1만번 호출하다는 의미로, elapsed time 값이 작으면 작을 수록 빠른 CPU 연산이 수행된다는 의미이다.  

https://github.com/akopytov/sysbench/issues/140
```
[ec2-user@ip-172-31-28-94 ~]$ sysbench cpu --cpu-max-prime=100000 \
                                           --threads=1 \
                                           --time=0 --events=10000 run
```

아래 테스트 결과에서 알수 있는 바와 같이 그라비톤은 총 소요시간이 87초, X64 는 220 초로 그라비톤이 2.5배 정도 빠르게 연산을 수행한다는 것을 볼 수 있다.

- graviton2
```
CPU speed:
    events per second:   114.02             (초당 10만개의 소수 계산을 114회 수행했다는 의미)

Throughput:
    events/s (eps):                      114.0161
    time elapsed:                        87.7069s       (총 소요시간)
    total number of events:              10000

Latency (ms):
         min:                                    8.76
         avg:                                    8.77
         max:                                    8.79
         95th percentile:                        8.74
         sum:                                87705.26

Threads fairness:
    events (avg/stddev):           10000.0000/0.00
    execution time (avg/stddev):   87.7053/0.00
```

- X64
```
CPU speed:
    events per second:    45.36

Throughput:
    events/s (eps):                      45.3573
    time elapsed:                        220.4715s
    total number of events:              10000

Latency (ms):
         min:                                   22.02
         avg:                                   22.05
         max:                                   22.16
         95th percentile:                       21.89
         sum:                               220468.57

Threads fairness:
    events (avg/stddev):           10000.0000/0.00
    execution time (avg/stddev):   220.4686/0.00
```

### FILE IO 성능 측정 ###

시스템의 메모리가 128GB 이므로, 총용량이 256GB 인 파일을 만든다음, 랜던 Read / Write 의 성능을 측정한다. 

https://imcreator.tistory.com/89 
```
[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G prepare

[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G --file-test-mode=rndrw --time=300 run

[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G cleanup
```

* graviton2


* X64




