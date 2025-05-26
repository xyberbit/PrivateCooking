#!/bin/bash
#
# i210 phy register tool through pcie mmio
# version 0.11 2021/09/19 by xyberbit
#
# 0.20 09/24/2021 soft reset added before test mode configured, normal mode added
# 0.11 09/19/2021 source and test mode supported
# 0.10 09/17/2021 first release, phy registers accessed from pcie mmio mdi register

bye="return 1 &>/dev/null; exit 1"
mode=0

mdicfg=0x0e04
mdic=0x0020
mdirdymsk=$((1<<28))
mdiwr=$((1<<26))
mdird=$((2<<26))
mdiadrmsk=0x1f
mdiadrshf=16
mdidatmsk=0xffff

phytstshf=13
phytstdef=0x1b00

help() {
  echo "i210 Phy Register Tool, version 0.11"
  echo "---"
  echo "usage: i210-phy {reg|test [val]}|normal"
  echo "  reg=    phy register address, val= data to write"
  echo "  test=   configure test mode (phy reg 9), val= 0:off, 1-4:test mode"
  echo "  normal= reset phy to normal operation"
  echo
}

err() {
  echo "$1!"
  echo
}

ckdvmm() {
  dvmm=`which devmem`
  [ -n "$dvmm" ] && dvmm=devmem
  [ -z "$dvmm" ] && dvmm=`which devmem2`
  [ -n "$dvmm" ] && dvmm=devmem2
  [ -z "$dvmm" ] && err "Command devmem or devmem2 required" && return 1
  echo "Command $dvmm settled."
}

# $1=offset, $2=width(8,16,32), $3=data
mmiorw() {
  local z=$2
  if [ $dvmm = devmem2 ]; then
    [ $2 -eq 8  ] && z=b
    [ $2 -eq 16 ] && z=h
    [ $2 -eq 32 ] && z=w
    z=`$dvmm $((mmio+$1)) $z $3 | grep -i "value at"`
    z="${z##*: }"
  else
    z=`$dvmm $((mmio+$1)) $z $3`
  fi
  [ -z "$3" ] && echo "$z"
}

fyrdy() {
  local i
  while [ 1 ]; do # wait for ready
    i=`mmiorw $mdic 32`
    [ $((i & mdirdymsk)) -eq 0 ] || break
    sleep 0.1
  done
  echo "$i"
}

fyrw() {
  local d=0
  local op=$mdird
  [ -n "$2" ] && op=$mdiwr && d=$2

  mmiorw $mdic 32 $(( ($1<<mdiadrshf)+op+d ))
  d=`fyrdy`
  [ $op -eq $mdird ] && printf "0x%04x\n" $((d & mdidatmsk))
}

cknum() {
  while [ 1 ]; do
    [[ "$1" =~ ^0x[0-9a-fA-F]+$ ]] && break
    [[ "$1" =~ ^[0-9]+$ ]] && break
    [[ "$1" =~ ^0o[0-7]+$ ]] && break
    echo "Invalid number '$1'!"
    return 1
  done
}

[ $# -lt 1 ] && eval "help; $bye"
[ $# -gt 2 ] && eval "help; $bye"
i=$#
data=
case "${1,,}" in
  test)
    mode=t; addr=9;;
  normal)
    [ $i -ne 1 ] && eval "help; $bye"
    mode=n; addr=0; data=0x9104;;
  *)
    cknum "$1" || eval $bye; addr=$(($1));;
esac

[ $addr -lt 0 -o $addr -gt 31 ] && err "reg '$1' out of range" && eval $bye
addr=`printf "0x%02x" $addr`

if [ -n "$2" ]; then
  cknum "$2" || eval $bye
  if [ $mode = t ]; then
    [ $2 -lt 0 -o $2 -gt 4 ] && err "test mode '$2' out of range" && eval $bye
    data=$((($2<<phytstshf)|phytstdef))
  else
    data=$(($2))
    [ $((data & ~mdidatmsk)) -ne 0 ] && err "val '$2' out of range" && eval $bye
  fi
  data=`printf "0x%04x" $data`
fi

info=`lspci | grep -i I210 2>/dev/null`
[ -z "$info" ] && err "Failed to detect i210 device" && eval $bye
echo "i210 detected."

slot=${info%% *}
[ -z "$slot" ] && err "Failed to locate i210 slot" && eval $bye
echo "Slot $slot identified." 

info=`lspci -s $slot -v | grep -i "memory at" | head -1 2>/dev/null`
[ -z "$info" ] && err "Failed to locate i210 memory" && eval $bye
info=($info)
mmio=0x${info[2]}
echo "Base memory $mmio located."

ckdvmm || eval "$bye"

i=`mmiorw $((mdicfg + 3)) 8`
[ $((i >> 7)) -ne 0 ] && error "MDI desination not for internal phy"

if [ -n "$data" ]; then
  case $mode in
    t) echo "Enter test mode '$2'.";;
    *) echo "Write data '$data' to reg '$addr'.";;
  esac
else
  case $mode in
    n) echo "Enter normal mode.";;
    t) echo "Read test mode.";;
    *) echo "Read from reg '$addr'.";;
  esac
fi

# reset phy and prepare for test
if [ $mode = t ] && [ -n "$data" ]; then
  fyrw 0 0x8140
  while [ 1 ]; do
    i=`fyrw 0`
    [ $((i & 0x8000)) -eq 0 ] && break
    sleep .5
  done
  sleep 1
fi

i=`fyrw $addr $data`
if [ -z "$data" ]; then
  [ $mode = t ] && i=$((i>>phytstshf))
  echo "$i"
fi

echo
