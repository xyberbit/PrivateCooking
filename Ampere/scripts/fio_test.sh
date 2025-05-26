#!/bin/bash
#./fio_test.sh 300 16 readwrite 4k

time=$1
job=$2
type=$3
block=$4

fio --verify=md5 --readwrite=$type --bs=$block --blockalign=512 --ioengine=libaio --direct=1 --runtime=$time --thread --norandommap --iodepth=8 --numjobs=$job --filename=/dev/sda:/dev/sdb --name test_fio
