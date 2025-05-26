#!/bin/sh

#NTSFC v0.01 (Not That Smart Fan Control) for eMAG and AmiBMC
#Usage:ntsfc <cpu-ssh> <cpu-pass> <bmc-ssh> <bmc-pass>
#***** it should be a simple loop in bmc however i2c issue makes this ssh solution

#control object : CPU tmperature degree C
#control range  : C=40..90, PWM%=24..99 (fan may stop under 24%)
#linear formula PWM% = (CPU_C - 40) * 1.5 + 24 or PWM% = (CPU_C - 24) * 1.5, where PWM% limited between 1..100

IPMI_PFX="ipmitool -H 127.0.0.1 -U ADMIN -P ADMIN"
VERB=

TEMP_SEQ="S0_SOC_Temp"
TEMP_LO=46
TEMP_OP=55
TEMP_HI=90
TEMP_R1=$((TEMP_OP-TEMP_LO))
TEMP_R2=$((TEMP_HI-TEMP_OP))
TEMP_READ="$IPMI_PFX sensor reading"
TEMP_UP_HYST=2
TEMP_DN_HYST=4
TEMP_REFRESH=1

FAN_SEQ="4 7"
DUTY_LO=6
DUTY_SI=22
DUTY_HI=100
DUTY_R1=$((DUTY_SI-DUTY_LO))
DUTY_R2=$((DUTY_HI-DUTY_SI))
FAN_MAN="$IPMI_PFX raw 0x3c 0x03 1"
FAN_DUTY="$IPMI_PFX raw 0x3c 0x04"

verb() {
  [ -z "$VERB" ] && return
  echo "$1"
}

temp_get() {
  local t t0=0
  for i in $TEMP_SEQ; do
    t=`$TEMP_READ $i`
    t=${t##* }
    [ $t -gt $t0 ] && t0=$t
  done
  echo $t0
}

duty_set() {
  duty=$1
  for i in $FAN_SEQ; do
    $FAN_DUTY $i $duty
  done
}

$FAN_MAN
verb "cooling manager disabled"

t=`temp_get`
verb "temp=$t"

if [ $t -le $TEMP_OP ]; then
  duty=$((DUTY_R1*(t-TEMP_LO)/TEMP_R1+DUTY_LO))
else
  duty=$((DUTY_R2*(t-TEMP_OP)/TEMP_R2+DUTY_SI))
fi
duty_set $duty
verb "duty=$duty"

te=0 # temp error

while true; do

  sleep $TEMP_REFRESH

  t=`temp_get`
  verb "temp=$t"

  t=$((t-TEMP_OP))
  if [ $t -lt 0 ]; then
    d=$((DUTY_SI+DUTY_R1*t/TEMP_R1))
    [ $t -eq $TEMP_DN_HYST))
    [ $td -eq 0 ] && te=$((te-1))
    [ $((te+TEMP_DN_HYST)) -eq 0 ] && td=$((td-1)) && te=0
    d=$((duty+td))

  elif[ $t -gt 0 ]; then

    td=$((t/TEMP_UP_HYST))
    [ $td -eq 0 ] && te=$((te+1))
    [ $((te-TEMP_UP_HYST)) -eq 0 ] && td=$((td+1)) && te=0
    t*
    d=$((duty+td))
  fi

  [ $d -ne $duty ] && duty_set $d
  verbose "duty=$duty"

done

55-90 33-100 TR2 DR2

