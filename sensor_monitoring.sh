#!/bin/bash

## start.sh을 통해서 실행

##Pre Check yum 설정 해야됨
Pre_Check()
{
    INST_CHECK=()
    INST_CHECK+=(`dpkg -l | grep -e ipmitool -e lm-sensors| awk '{print $2}'`)
    INST_CHECK+=(`yum list installed | grep -e ipmitool -e lm_sensors`)
    
    if [ ${#INST_CHECK[@]} -eq 0 ]; then
        echo `apt-get install ipmitool -y > /dev/null 2>&1` 
        echo `apt-get install lm-sensors -y > /dev/null 2>&1`
        echo `apt-get install lm_sensors -y > /dev/null 2>&1`
    fi

    if [ ${#INST_CHECK[@]} -eq 1 ]; then
        if [ "${INST_CHECK[0]}" = "ipmitool" ]; then
            echo `apt-get install lm-sensors -y > /dev/null 2>&1`
            echo `apt-get install lm_sensors -y > /dev/null 2>&1`
        fi
        if [ "${INST_CHECK[0]}" = "lm-sensors" ] || [ "${INST_CHECK[0]}" = "lm_sensors" ]; then
            echo `apt-get install ipmitool -y > /dev/null 2>&1`
        fi
    fi
}

Pre_Check


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
CPU_CORE_COUNT=`sensors | grep -c Core` 

INIT_SENSOR()
{
SENSOR_FILE=sensor.txt 

SENSOR_NAME= 
SENSOR_NAME_REAL=() 

SENSOR_ID_REAL=() 
EXCEL_SUB= 

ipmitool sensor | awk -F '|' '{print $1 "|" $2 "|" $3}' > $SENSOR_FILE
    var=0
    for (( ; ; ))
    do
        var=$((var+1))

        SENSOR_VALUE_CHECK=`cat $SENSOR_FILE | sed -n "${var}"P | awk -F '|' '{print $2}' | sed 's/ //g'`
        if [ -z "$SENSOR_VALUE_CHECK" ]; then
            break;
        fi
        
        DEVICE_CHECK=`cat sensor.txt | sed -n "${var}"P | awk -F '|' '{print $3}' | sed 's/ //g'`
        
        if [ "$DEVICE_CHECK" = "Volts" ] || [ "$DEVICE_CHECK" = "discrete" ]; then
            continue
        fi

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
        fi
    done



    DEVICE_CHECK=
    DEVICE_VAR=0
    EXCEL_VALUE=$CUR_TIME,
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


CPU_CORE_TEMP()
{
    
    CORE_TEMP=`sensors | grep Core | awk '{print $3}' | sed 's/+//g' | sed 's/°//g' | sed 's/C//g'`
    CORE_TEMP_ARR=()
    CORE_TEMP_ARR+=($CORE_TEMP)
    if [ -z "$CORE_TEMP" ]||[ "null" = "$CORE_TEMP" ]; then
        echo "[$CUR_TIME] CPU CORE${var} Temperature connection error" >> $FILE_PATH/$LOG_FILE
    fi

    for var in "${CORE_TEMP_ARR[@]}"
    do
        PRINT_SENSOR=$PRINT_SENSOR,\ ${var}
    done

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

Init()
{
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
    if [ ! -e $FILE_PATH/$FILE_NAME ]; then
        touch $FILE_PATH/$FILE_NAME
        echo "date, Memory %, CPU %, DISK % $EXCEL_SUB" >> $FILE_PATH/$FILE_NAME
    fi

    FAN_Init=
    CORE_Init=
    PACKAGE_Init=
}


Sensor_Reading()
{
    CUR_TIME=`date +%Y-%m-%d\ %H:%M:%S`

    MEMORY_TOTAL=`free | grep ^Mem | awk '{print $2}'`
    MEMORY_USED=`free | grep ^-/+ | awk '{print $3}'`
    MEMORY_PERCENT=$((100*MEMORY_USED/MEMORY_TOTAL))
    
    CPU_PERCENT=`top -b -n 1 | grep -i cpu\(s\)| awk -F, '{print $4}' | tr -d "%id," | awk '{print 100-$1}'`
 
    DISK_TOTAL=`df -P | grep -v ^Filesystem | awk '{sum += $2} END { print sum; }'`
    DISK_USED=`df -P | grep -v ^Filesystem | awk '{sum += $3} END { print sum; }'`
    DISK_PERCENT=$((100*$DISK_USED/$DISK_TOTAL))

    PRINT_SENSOR
    BOARD_POWER

    echo "[$CUR_TIME], $MEMORY_PERCENT, $CPU_PERCENT, $DISK_PERCENT, $EXCEL_VALUE$bo_power" >> $FILE_PATH/$FILE_NAME

}


######### MAIN ##########
Init 


for (( File_Check_var=`date +%Y%m%d`-1  ; File_Check_var > 20221225 ; File_Check_var-- ));
do
    if [ -e $FILE_PATH/"$File_Check_var"_sensor_log.csv ]; then
        gzip $FILE_PATH/"$File_Check_var"_sensor_log.csv
    fi
done

KERNEL_PANIC=`date +%Y%m%d%H%M`
KERNEL_PANIC2="dmesg.$KERNEL_PANIC"

PRE_Date=`date +%Y%m%d` 

for (( ; ; ));
do
    CUR_Date=`date +%Y%m%d` 
    if [ $PRE_Date != $CUR_Date ]; then
        
        gzip $FILE_PATH/"$PRE_Date"_sensor_log.csv

        PRE_Date=$CUR_Date
        Init 
    fi
    Sensor_Reading 
    dmesg_error
    dmesg_warning
    rmDmesg=`dmesg -c`
    echo $rmDmesg

    sleep $interval 

done

cd /var/crash/ 

if [ -e $KERNEL_PANIC ];then
    cd ./$KERNEL_PANIC
    if [ -e $KERNEL_PANIC2 ];then
        Oops_check=`cat $KERNEL_PANIC2 | grep "Oops: 0002"`
        SysRq_check=`cat $KERNEL_PANIC2 | grep SysRq`
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
