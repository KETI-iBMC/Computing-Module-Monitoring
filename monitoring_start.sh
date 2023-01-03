#!/bin/bash

# sensor monitoring 주기 설정 (second)

# 센서 데이터 (년월일_sensor_log.csv)형태로 저장
# 장애 및 이상 수집 데이터 (dmesgERROR.csv, dmesgWARN.csv)형태로 저장


export interval=0 #0초 설정 (센서 데이터 송수신 1~2초 추가)


#현재 실행중인 파일 종료

CUR_RUN=()
CUR_RUN+=(`ps -aux | grep -e sensor_monitoring.sh | awk '{print $2}'`)

for var in ${CUR_RUN[@]}
do
    kill -9 ${var}
done


./sensor_monitoring.sh > /dev/null 2>&1