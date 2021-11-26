#!/usr/bin/sh
HOST=192.168.1.22
PORT=2881 
USER=root@test
DB=test
THREADS=4
TABLE_SIZE=1000
TABLES=3
TIME=300 
REPORT_INTERVAL=10

sysbench --db-ps-mode=disable --mysql-host=$HOST --mysql-port=$PORT \
         --rand-type=uniform --rand-seed=26765 \
         --mysql-user=$USER --mysql-db=$DB \
         --threads=$THREADS \
         --tables=$TABLES --table_size=$TABLE_SIZE \
         --time=$TIME --report-interval=$REPORT_INTERVAL \
         /home/shk/oceanbase/subplan.lua $1

# HOST=your-ob-ip
# PORT=2881
# USER=root@test
# DB=test
# THREADS=128
# TABLE_SIZE=100000
# TIME=600
# REPORT_INTERVAL=10
# sysbench --db-ps-mode=disable --mysql-host=$HOST --mysql-port=$PORT \
#          --rand-type=uniform --rand-seed=26765 \
#          --mysql-user=$USER --mysql-db=$DB \
#          --threads=$THREADS --tables=$TABLES --table_size=$TABLE_SIZE \
#          --warmup-time=30 \
#          --time=$TIME --report-interval=$REPORT_INTERVAL \
#          oltp_read_write $1  # arg can be cleanup/prepare/run