#!/bin/bash
 
FORMAT="%Y-%m-%d %T"

    now=$(date +%s)
    cputime_line=$(grep -m1 "\.clock" /proc/sched_debug)

    if [[ $cputime_line =~ [^0-9]*([0-9]*).* ]]; then
        cputime=$((BASH_REMATCH[1] / 1000))
        echo $cputime
    fi
cputime=`cat /proc/uptime | awk -F '.' '{print $1}'`
    dmesg -l warn | while IFS= read -r line; do
        if [[ $line =~ ^\[\ *([0-9]+)\.[0-9]+\]\ (.*) ]]; then
            stamp=$((now-cputime+BASH_REMATCH[1]))
            #echo "[$(date +"${FORMAT}" --date=@${stamp})] ${BASH_REMATCH[2]}"
            echo ${stamp}
        else
            echo "$line"
        fi
    done