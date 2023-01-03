#!/bin/bash


SENSOR_FILE=sensor.txt

firSENSOR_ID=() #모든 센서 ID
snd_SENSOR_ID=() #값이 있는 ID
SENSOR_NAME=
SENSOR_NAME_REAL=()
SENSOR_ID_REAL=()
CUR_TIME=`date +%Y-%m-%d\ %H:%M:%S`
EXCEL_SUB=date
tmp_var=2

ipmitool sensor | awk -F '|' '{print $1 "|" $2 "|" $3}' > $SENSOR_FILE


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
        EXCEL_VALUE=$EXCEL_VALUE\ $SENSOR_VALUE,
    fi
done

##센서값 출력 테스트용
for (( var=0 ; var < ${#SENSOR_NAME_REAL[*]} ; var++));
do
    echo ${SENSOR_NAME_REAL[${var}]} ${SENSOR_ID_REAL[${var}]}
done


echo ${SENSOR_ID_REAL[@]}

