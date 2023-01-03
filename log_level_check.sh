#!/bin/bash


CUR_PATH=`pwd`
ERROR_LOG_FILE=dmesgERROR.csv
ERROR_Temp_FILE=dmesgErrTemp.csv
WARNING_Temp_FILE=dmesgWarnTemp.csv
WARNING_LOG_FILE=dmesgWARN.csv
FILE_PATH=$CUR_PATH
CUR_TIME=""
LOG_FILE=test.csv
ERR_WARN_CHECK=1
###수정중###
#### 같은 날짜에 꺼졌을때 에러 로그 중복 처리
SYS_ERR_check()
{
    ERR_LOG=`dmesg -l err | sed -n "$((ERR_VAR+1))"P`
    if [ ! -z "$ERR_LOG" ]; then
        ERR_VAR=$((ERR_VAR+1))
        echo "[$CUR_TIME] $ERR_LOG" >> $LOG_FILE
    fi
}

###수정중###
#### 같은 날짜에 꺼졌을때 에러 로그 중복 처리
#### ERR, WARN 구별
SYS_WARN_check()
{
    WARN_LOG=`dmesg -l warn | sed -n "$((WARN_VAR+1))"P`
    if [ ! -z "$WARN_LOG" ]; then
        WARN_VAR=$((WARN_VAR+1))
        echo "[$CUR_TIME] $WARN_LOG" >> $LOG_FILE
    fi
}

Monitoring()
{
    Monitoring_LOG=`./log_sensor.sh`
    echo "$Monitoring_LOG" >> $LOGFILE
}

dmesg_error () {
    FORMAT="%Y-%m-%d %T"

    now=$(date +%s)
    cputime_line=$(grep -m1 "\.clock" /proc/sched_debug)

    if [[ $cputime_line =~ [^0-9]*([0-9]*).* ]]; then
        cputime=$((BASH_REMATCH[1] / 1000))
    fi

    dmesg -l err | while IFS= read -r line; do
        if [[ $line =~ ^\[\ *([0-9]+)\.[0-9]+\]\ (.*) ]]; then
            stamp=$((now-cputime+BASH_REMATCH[1]))
            echo "[$(date +"${FORMAT}" --date=@${stamp})] ${BASH_REMATCH[2]}" >> ${ERROR_Temp_FILE}
        else
            echo "$line"
        fi
    done
    writeCMD=`cat ${ERROR_Temp_FILE} >> ${ERROR_LOG_FILE}` 
    echo $writeCMD
    rmCMD=`rm ${ERROR_Temp_FILE} > /dev/null 2>&1`
    echo $rmCMD

}

dmesg_warning () {
    FORMAT="%Y-%m-%d %T"

    now=$(date +%s)
    cputime_line=$(grep -m1 "\.clock" /proc/sched_debug)

    if [[ $cputime_line =~ [^0-9]*([0-9]*).* ]]; then
        cputime=$((BASH_REMATCH[1] / 1000))
    fi

    dmesg -l warn | while IFS= read -r line; do
        if [[ $line =~ ^\[\ *([0-9]+)\.[0-9]+\]\ (.*) ]]; then
            stamp=$((now-cputime+BASH_REMATCH[1]))
            echo "[$(date +"${FORMAT}" --date=@${stamp})] ${BASH_REMATCH[2]}" >> ${WARNING_Temp_FILE}
        else
            echo "$line"
        fi
    done
    writeCMD=`cat ${WARNING_Temp_FILE} >> ${WARNING_LOG_FILE}` 
    echo $writeCMD
    rmCMD=`rm ${WARNING_Temp_FILE} > /dev/null 2>&1`
    echo $rmCMD

    
}

for (( ; ; ));
do
    # SYS_ERR_check
    # SYS_WARN_check
    # Monitoring
    dmesg_error
    dmesg_warning
    rmDmesg=`dmesg -c`
    echo $rmDmesg
    sleep 5
done


