#!/bin/bash

host=192.168.205.22
delay=2
count=-4
avg=
sum=0

while [ 1 ]; do
    a=(`ipmitool -H $host -U admin -P password -I lanplus dcmi power reading | grep Inst`)
    a=$((a[3]*100))
    sum=$((sum+a))
    echo -en "$count:"
    if [ $count -gt 0 ]; then
        v=($avg)
        avg="${v[1]} ${v[2]} ${v[3]} ${v[4]}"
        v=$(((v[0]+v[1]+v[2]+v[3]+v[4])/5))
        s=$((sum/(count+5)))
        echo -en "\t$((v/100)).$((v%100))"
    else
        echo -en "\t$((a/100)).$((a%100))"
    fi
    v=$((sum/(count+5))) 
    echo -e "\t$((v/100)).$((v%100))"
    avg="$avg $a"
    count=$((count+1))
    sleep $delay
done

