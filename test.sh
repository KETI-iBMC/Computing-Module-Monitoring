#!/bin/bash

var=0
for (( ; ; ))
do
    var=$((var+1))
    if [ ${var} -eq 100000 ]; then
        echo 123
    fi
done

