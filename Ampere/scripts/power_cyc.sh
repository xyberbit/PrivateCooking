#!/bin/bash
BMCIP=127.0.0.1
OSIP=10.1.27.176

if [ $# -gt 0 ]; then
OSIP=$1
fi
echo $OSIP
echo $OSIP >> test.log
#This test for power cycle test

TESTCOUNT=1
POWERWAIT=50


while [ 1 ]; do
	echo -e "Start test -------------------- $(date +"%m/%d %H:%M:%S") --------- $TESTCOUNT\r\n"  >> test.log
	echo "Test ------- " $TESTCOUNT

	# wait BMC on line
	ping -c 1 $BMCIP  > /dev/null
	PINGRESULT=$?
	printf "Wait BMC ready ."
	while [ $PINGRESULT != 0 ]; do
		printf "."
		sleep 3
		ping -c 1 $BMCIP  > /dev/null
		PINGRESULT=$?		
	done
	echo "."
	sleep 3



	#Send command to turn on HOST (CentOS)
	echo -e "power on ------------ $(date +"%m/%d %H:%M:%S") ---   $TESTCOUNT\r\n" >> test.log
  devmem 0x1e78909c
  devmem 0x1e78909c >> test.log

	ipmitool -I lanplus -H $BMCIP -U admin -P password chassis power on
  sleep 60
  PWaitValue=$POWERWAIT

	# wait HOST on line
	ping -c 1 $OSIP > /dev/null
	PINGRESULT=$?
	printf "Wait HOST ready ."
	while [ $PINGRESULT != 0 -a $PWaitValue != 0 ]; do
		printf "."
		sleep 3
		ping -c 1 $OSIP > /dev/null
		PINGRESULT=$?		
    PWaitValue=$(($PWaitValue-1))
	done	
	echo "."
	sleep 10

  if [ $PWaitValue == 0 ]; then
    echo "Power on command fail !!!"
    echo "Power on command fail !!!" >> test.log
  fi

	#Send command to turn off HOST (CentOS)
	echo -e "power off ----------- $(date +"%m/%d %H:%M:%S") ---   $TESTCOUNT\r\n" >> test.log
	ipmitool -I lanplus -H $BMCIP -U admin -P password chassis power off
	sleep 20

	echo -e "End test -------------------- $(date +"%m/%d %H:%M:%S") ---   $TESTCOUNT\r\n"  >> test.log
	echo -e "\r\n"  >> test.log
	echo ""


	TESTCOUNT=$(($TESTCOUNT+1))

done