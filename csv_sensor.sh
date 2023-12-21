#!/bin/bash
#``
#사전 설치 패키지




#ubuntu
echo `apt-get update > /dev/null 2>&1`
echo `apt-get install ipmitool -y > /dev/null 2>&1` 
echo `apt-get install lm-sensors -y > /dev/null 2>&1`

#CentOS
echo `yum update > /dev/null 2>&1`
echo `yum install ipmitool -y > /dev/null 2>&1` 
echo `yum install lm_sensors -y > /dev/null 2>&1`

#### Sensor 오류 사용자 정의 오류 추가
#### 시간 delay 발생 원인?
#### error list sh 이 아닌 다른걸로 가져오는 방법


CUR_PATH=`pwd`
ERROR_LOG_FILE=dmesgERROR.csv
ERROR_Temp_FILE=dmesgErrTemp.csv
WARNING_Temp_FILE=dmesgWarnTemp.csv
WARNING_LOG_FILE=dmesgWARN.csv

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
    writeCMD=`cat ${ERROR_Temp_FILE} >> $FILE_PATH/${ERROR_LOG_FILE}`
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
    writeCMD=`cat ${WARNING_Temp_FILE} >> $FILE_PATH/${WARNING_LOG_FILE}`
    echo $writeCMD
    rmCMD=`rm ${WARNING_Temp_FILE} > /dev/null 2>&1`
    echo $rmCMD

    
}


#get Power
POWER_COUNT=()
bo_power=`sensors | grep power | grep W | awk -F ':' '{print $1}'`
POWER_COUNT+=($bo_power)
CPU_CORE_COUNT=`sensors | grep -c Core` # 코어 개수
interval_second=5 #반복주기 (sec)

INIT_SENSOR()
{
SENSOR_FILE=sensor.txt 

SENSOR_NAME= #센서 이름
SENSOR_NAME_REAL=() #값이 있는 센서 이름

SENSOR_ID_REAL=() #값이 있는 센서 ID
EXCEL_SUB= #엑셀 초기 머리글

ipmitool sensor | awk -F '|' '{print $1 "|" $2 "|" $3}' > $SENSOR_FILE

#센서 NAME찾는 파트
    for (( ; ; ))
    do
        var=$((var+1))

        #센서 값 확인
        SENSOR_VALUE_CHECK=`cat $SENSOR_FILE | sed -n "${var}"P | awk -F '|' '{print $2}' | sed 's/ //g'`
        if [ -z "$SENSOR_VALUE_CHECK" ]; then
            break;
        fi
        
        #DEVICE Volts 무시
        DEVICE_CHECK=`cat sensor.txt | sed -n "${var}"P | awk -F '|' '{print $3}' | sed 's/ //g'`
        
        if [ "$DEVICE_CHECK" = "Volts" ] || [ "$DEVICE_CHECK" = "discrete" ]; then
            continue
        fi

        #값이 있는 센서 구별
        if [ "$SENSOR_VALUE_CHECK" != "na" ]; then
            SENSOR_NAME_TMP=`cat $SENSOR_FILE | sed -n "${var}"P | awk -F '|' '{print $1 "|"}' `
            tmp_var=1
            for (( ; ; ))
            do
                if [ ${#SENSOR_NAME_TMP} -eq $((tmp_var)) ]; then
                    SENSOR_NAME=${SENSOR_NAME_TMP:0:$((tmp_var-1))}
                    break
                fi
                echo "$SENSOR_NAME_TMP" | cut -c $((tmp_var))-$((tmp_var+1)) > tmp.txt
                SENSOR_NAME_tok=`cat tmp.txt`
                if [ "$SENSOR_NAME_tok" = "  " ] || [ "$SENSOR_NAME_tok" = " |" ]; then
                    SENSOR_NAME=${SENSOR_NAME_TMP:0:$((tmp_var-1))}
                    break
                fi
                tmp_var=$((tmp_var+1))
            done
            EXCEL_SUB="$EXCEL_SUB, $SENSOR_NAME"
            SENSOR_NAME=`echo "$SENSOR_NAME" | tr ' ' '!'`
            SENSOR_NAME_REAL+=($SENSOR_NAME)
            SENSOR_NAME=
            #SENSOR_NAME+=(`cat $SENSOR_FILE | sed -n "${var}"P | awk -F '|' '{print $1}' | tr ' ' '!'`)
        fi
    done



    DEVICE_CHECK=
    DEVICE_VAR=0
    EXCEL_VALUE=$CUR_TIME,
#센서 ID찾는 파트
    SENSOR_ID_TMP=`ipmitool sdr -v | grep 'Sensor ID' | awk -F '(' '{print $2}' | sed 's/)//g' `
    SENSOR_ID+=($SENSOR_ID_TMP)
    for var in ${SENSOR_ID[@]}
    do
        DEVICE_VAR=$((DEVICE_VAR+1))
        DEVICE_CHECK=`cat sensor.txt | sed -n "$DEVICE_VAR"P | awk -F '|' '{print $3}' | sed 's/ //g'` 
        SENSOR_VALUE_CHECK=`cat sensor.txt | sed -n "$DEVICE_VAR"P | awk -F '|' '{print $2}' | sed 's/ //g'` 
        
        if [ "$SENSOR_VALUE_CHECK" = "na" ]; then
            continue
        fi
        SENSOR_VALUE=`ipmitool raw 0x04 0x2d ${var} | awk '{print $1}'`
        
        if [ ! -z "$SENSOR_VALUE" ]; then
            SENSOR_VALUE=$((16#$SENSOR_VALUE))
            if [ "$DEVICE_CHECK" = "degreesC" ]; then
                SENSOR_VALUE="$SENSOR_VALUE".000
            fi
            if [ "$DEVICE_CHECK" = "RPM" ]; then
                SENSOR_VALUE="$SENSOR_VALUE"00
            fi
            if [ "$DEVICE_CHECK" = "Volts" ] || [ "$DEVICE_CHECK" = "discrete" ]; then
                continue
            fi

            SENSOR_ID_REAL+=(${var})
        fi
    done
    rm tmp.txt
}


#센서 표기값 설정 및 출력 정리 함수
PRINT_SENSOR()
{
    EXCEL_VALUE=
    for (( var=0 ; var < ${#SENSOR_NAME_REAL[*]} ; var++));
    do
        CC=`echo "${SENSOR_NAME_REAL[${var}]}" | tr '!' ' '`
        DEVICE_CHECK=`cat sensor.txt | grep "$CC" | awk -F '|' '{print $3}' | sed 's/ //g'`
        SENSOR_VALUE=`ipmitool raw 0x04 0x2d ${SENSOR_ID_REAL[${var}]} | awk '{print $1}'`
        
        SENSOR_VALUE=$((16#$SENSOR_VALUE))
        if [ "$DEVICE_CHECK" = "degreesC" ]; then
            SENSOR_VALUE="$SENSOR_VALUE".000
        fi
        if [ "$DEVICE_CHECK" = "RPM" ]; then
            SENSOR_VALUE="$SENSOR_VALUE"00
        fi
        EXCEL_VALUE=$EXCEL_VALUE\ $SENSOR_VALUE,
    done
    DEVICE_CHECK=
    SENSOR_VALUE=
}


#CPU CORE VALUE 찾는 파트
CPU_CORE_TEMP()
{
# for var in "${CORE_NUM[@]}"
    # do
    #TEMP=$((var+2))
    
    CORE_TEMP=`sensors | grep Core | awk '{print $3}' | sed 's/+//g' | sed 's/°//g' | sed 's/C//g'`
    #CORE_TEMP=`cat test.json | jq '."coretemp-isa-0000"."Core '${var}'"."temp'$((var+2))'_input"'`
    CORE_TEMP_ARR=()
    CORE_TEMP_ARR+=($CORE_TEMP)
    if [ -z "$CORE_TEMP" ]||[ "null" = "$CORE_TEMP" ]; then
        echo "[$CUR_TIME] CPU CORE${var} Temperature connection error" >> $FILE_PATH/$LOG_FILE
    fi

    for var in "${CORE_TEMP_ARR[@]}"
    do
        PRINT_SENSOR=$PRINT_SENSOR,\ ${var}
    done

# done
}

BOARD_POWER()
{
    POWER_COUNT=()

    bo_power=`sensors | grep power | awk '{print $2}'`
    POWER_COUNT+=($bo_power)
    bo_power=
    for var in ${POWER_COUNT[@]}
    do
        bo_power=$bo_power\ ${var},
    done
}

#파일 설정 함수
Init()
{
    #모니터링 Log 파일 생성
    INIT_SENSOR

    if [ ! -d log_data ]; then
        mkdir -p log_data
    fi
    DIR_NAME=log_data
    FILE_NAME=`date +%Y%m%d`_sensor_log.csv
    CUR_PATH=`pwd`
    FILE_PATH=$CUR_PATH/$DIR_NAME

    for var in ${POWER_COUNT[@]}
    do
        EXCEL_SUB=$EXCEL_SUB,\ ${var}
    done
    #엑셀파일 초기 설정
    #for var in "${FAN_NUM[@]}"
    # FAN_COUNT=`sensors | grep -c fan` #팬 개수
    # if [ 0 -eq $FAN_COUNT ]; then
    #     IPMI_FAN
    # fi
    
    # for ((var=0 ; var < $PACKAGE_COUNT ; var++));
    # do
    #     PACKAGE_Init=$PACKAGE_Init,\ PACKAGE\ ${var}
    # done
    #for var in "${FAN_NUM[@]}"
    # for ((var=1 ; var <= $FAN_COUNT ; var++));
    # do
    #     FAN_Init=$FAN_Init,\ Fan\ ${var}
    # done
    
    #for var in "${CORE_NUM[@]}"
    # for ((var=1 ; var <= $CPU_CORE_COUNT ; var++));
    # do
    #     CORE_Init=$CORE_Init,\ Core\ ${var}
    # done

    if [ ! -e $FILE_PATH/$FILE_NAME ]; then
        touch $FILE_PATH/$FILE_NAME
        echo "date, Memory %, CPU %, DISK % $EXCEL_SUB" >> $FILE_PATH/$FILE_NAME
    fi

    FAN_Init=
    CORE_Init=
    PACKAGE_Init=
    #에러 Log 파일 생성
    #LOG_FILE=`date +%Y%m%d`_err.log
    #echo $LOG_FILE
    #if [ ! -e $FILE_PATH/$LOG_FILE ]; then
    #    touch $FILE_PATH/$LOG_FILE
    #fi
}




#Sensor_Reading 함수
Sensor_Reading()
{
    CUR_TIME=`date +%Y-%m-%d\ %H:%M:%S` #현재 시간   

##MEMORY 사용율
    MEMORY_TOTAL=`free | grep ^Mem | awk '{print $2}'`
    MEMORY_USED=`free | grep ^-/+ | awk '{print $3}'`
    MEMORY_PERCENT=$((100*MEMORY_USED/MEMORY_TOTAL))
    
##CPU 사용율
    CPU_PERCENT=`top -b -n 1 | grep -i cpu\(s\)| awk -F, '{print $4}' | tr -d "%id," | awk '{print 100-$1}'`
 
##DISK 사용율
    DISK_TOTAL=`df -P | grep -v ^Filesystem | awk '{sum += $2} END { print sum; }'`
    DISK_USED=`df -P | grep -v ^Filesystem | awk '{sum += $3} END { print sum; }'`
    DISK_PERCENT=$((100*$DISK_USED/$DISK_TOTAL))

#FAN status 구하기 위함
##FAN SPEED 시스템 팬 3개
    #sensors -j > test.json

    #FAN 얻는 TOOL 결정하기 위함
    # FAN_Exist_Check=`sensors | grep fan`
    # if [ -z "$FAN_Exist_Check" ]; then
    #     IPMI_FAN
    # else
    #     SENSORS_FAN
    # fi

#CPU TEMPERATURE 
#    PACKAGE_TEMP_Reading

##cpu core temp
#    CPU_CORE_TEMP
    PRINT_SENSOR
    BOARD_POWER
###date, Memory %, CPU %, DISK %, PACKAGE %, , Fan 1, Fan 2, Fan 3 , Core 0, Core 1, Core 2, Core 3, Core 4, Core 5

    echo "[$CUR_TIME], $MEMORY_PERCENT, $CPU_PERCENT, $DISK_PERCENT, $EXCEL_VALUE$bo_power" >> $FILE_PATH/$FILE_NAME
    #echo "[$CUR_TIME], $MEMORY_PERCENT, $CPU_PERCENT, $DISK_PERCENT $PACKAGE_TEMP$PRINT_SENSOR"

}


######### MAIN ##########
Init #초기설정 실행

#이전 날짜 로그 압축
for (( File_Check_var=`date +%Y%m%d`-1  ; File_Check_var > 20221200 ; File_Check_var-- ));
do
    if [ -e $FILE_PATH/"$File_Check_var"_sensor_log.csv ]; then
        gzip $FILE_PATH/"$File_Check_var"_sensor_log.csv
    fi
done

#Kernel Panic 변수 선언
KERNEL_PANIC=`date +%Y%m%d%H%M`
KERNEL_PANIC2="dmesg.$KERNEL_PANIC"

PRE_Date=`date +%Y%m%d` # 이전날짜 저장하기위함

for (( ; ; ));
do
    #Sensor LOG 파일 현재 날짜에 맞춰 생성
    CUR_Date=`date +%Y%m%d` # 현재 날짜
    if [ $PRE_Date != $CUR_Date ]; then
        gzip "$PRE_Date"_err.log
        gzip "$PRE_Date"_sensor_log.csv
        PRE_Date=$CUR_Date
        Init #새로운 로그 파일 생성
    fi
    Sensor_Reading # Sensor_Reading 함수
    dmesg_error
    dmesg_warning
    rmDmesg=`dmesg -c`
    echo $rmDmesg

    sleep $interval_second #반복 주기 (second)

    # SYS_ERR_check # Error log Reading 함수
    # SYS_WARN_check # Warning log Reading 함수

done

#Kernel panic
cd /var/crash/ 

if [ -e $KERNEL_PANIC ];then
    cd ./$KERNEL_PANIC
    if [ -e $KERNEL_PANIC2 ];then
        Oops_check=`cat $KERNEL_PANIC2 | grep "Oops: 0002"`
        SysRq_check=`cat $KERNEL_PANIC2 | grep SysRq`
        #echo $KERNEL_PANIC3
		if [ ! -z "$SysRq_check" ]; then
            echo $SysRq_check
            echo "[$CUR_TIME] Someone uses sysrq to trigger" >> $FILE_PATH
        fi
        if [ ! -z "$Oops_check" ];then
            echo $Oops_check
            echo "[$CUR_TIME] Oops log ocurred current kernel state panic" >> $FILE_PATH
        fi
    fi
fi

#Error List 확인 <<
