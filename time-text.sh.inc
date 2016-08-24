#!/bin/bash

set -u

function time_text {    
    function plural() {
        if [ $1 -eq 1 ]; then
            echo "$1 $2"
        elif [ $1 -gt 1 ]; then
            echo "$1 $2s"
        fi
    }
    
    and=0
    
    (( year=$1/31536000 ))
    (( s=$1-$year*31536000 ))
    ((
    week=$s/604800,
    day=$s/86400%7,
    hour=$s/3600%24,
    minute=$s/60%60,
    second=$s%60
    ))
    
    if [ $2 ]; then
        [ $2 = "minutes" ] && let second=0
        [ $2 = "hours" ] && let {second,minute}=0
        [ $2 = "days" ] && let {second,minute,hour}=0
        [ $2 = "weeks" ] && let {second,minute,hour,day}=0
        [ $2 = "years" ] && let {second,minute,hour,day,week}=0
    fi
    result=
 
    for period in second minute hour day week year; do
        [ ${!period} -gt 0 ] && [ $and -eq 1 ] && result="and $result"
        [ ${!period} -gt 0 ] && result="$(plural ${!period} $period) $result" && (( and=$and+1 ))
    done

    [ -z "$result" ] && result="0 $2"
    echo $result
}

export -f time_text

#time_text $ARG ${2:-seconds}
