#!/bin/bash

EXIT="return $RET >&/dev/null; exit $RET"
EXOK="RET=0; $EXIT"
EXER="RET=1; $EXIT"

[ $# -eq 0 ] && {
  echo "NVParam Calculator for Altra Family"
  echo "usage: ${0##*/} data"
  echo
  eval "$EXER"
}

# $1=array string
crc16() {
  local crc=0
  for i in $1; do
    crc=$((crc ^ (i << 8)))
    for j in 0 1 2 3 4 5 6 7; do
      crc=$((crc << 1))
      [ $((crc & 0x10000)) -ne 0 ] && crc=$((crc ^ 0x1021))
    done
    crc=$((crc & 0xffff))
  done
  echo $((crc & 0xffff))
}

# $1=data $2=attr
nvgen() {
  local arr="$(($1        & 0xff))"
  arr="$arr $((($1 >>  8) & 0xff))"
  arr="$arr $((($1 >> 16) & 0xff))"
  arr="$arr $((($1 >> 24) & 0xff))"
  arr="$arr $2"
  local crc=`crc16 "$arr 0 0"`
  echo -n "$arr $((crc & 0xff)) $((crc >> 8))"
}

bin=
att="0xff 0xff"

for i in `nvgen $(($1 & 0xffffffff)) "$att"`; do
  bin="$bin\\`printf x%02x $i`"
done
echo "$bin"

eval "$EXOK"
