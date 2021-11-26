#!/usr/bin/sh
sysbench --db-ps-mode=disable --mysql-host=192.168.1.22 --mysql-port=2881 --\
mysql-user=root@test --mysql-db=test --threads=2 --table_size=1000 --\
time=60 --report-interval=10 oltp_read_write run