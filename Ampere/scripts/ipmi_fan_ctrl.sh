#!/bin/bash

USER=admin
PASS=admin
DUTY=0

ipmi() {
  ipmitool -H $HOST -U $USER -P $PASS "$@"
  sleep 1
} 

cool() {
  local mode=0
  [ "$1" = 1 ] && mode=1
  echo -n "Cooling manager "
  ipmi raw 0x3c 0x0b $mode >&/dev/null
  [ "$mode" = 1 ] && echo disabled. || echo enabled.
}

while [ 1 ]; do
  op="$1"
  shift
  [ -z "$op" ] && break
  case "$op" in
    -H|-h) HOST="$1";;
    -U|-u) USER="$1";;
    -P|-p) PASS="$1";;
    -D|-d) DUTY="$1";;
    *) echo "Unknown option '$op'!!!"; exit 1;;
  esac
  shift
done

[ -z "$HOST" ] && { echo Host undefined!!!; exit 1; }
ping -c 1 -W 1000 $HOST >&/dev/null || { echo Host unreachable!!!; exit 1; }

[ $DUTY = 0 ] && {
  cool
} || {
  cool 1
  i=1
  while [ 1 ]; do
    [ `ipmi raw 0x3c 0x08 $i $DUTY` = 00 ] || break
    echo Fan $i duty $DUTY% set.
    i=$((i+1))
  done
}
