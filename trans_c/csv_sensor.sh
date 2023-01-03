#!/bin/bash

##sensor 프로세스메모리 확인

for (( ; ; ));
do
    abc=`ps -aux | grep ./min_test | grep -v grep|awk '{print $2", "$3", "$4", "$5", "$6}'`
    CUR_TIME=`date +%Y-%m-%d\ %H:%M:%S`
    echo $CUR_TIME,\ $abc >> process_memory.txt
    sleep 5
done