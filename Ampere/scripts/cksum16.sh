#!/bin/bash
#
# byte based little-endian 16-bit checksum calculator
# byte pair to make word which must be in the same line
#
# $1 filename
# $2 tag1
# $3 tag2

QUIT="return 1>&/dev/null; exit 1"
proc=
sum=0

[ -f "$1" ] || { echo \"$1\" not existing; eval $QUIT; }
[ -z "$2" ] && { echo param2 missing; eval $QUIT; }
[ -z "$3" ] && { echo param3 missing; eval $QUIT; }

while IFS= read -r line; do

  if [ -z "$proc" ]; then
    [[ "$line" =~ "$2" ]] || continue
    echo "$2"
    proc=1
  fi

  [[ "$line" =~ "$3" ]] && {
    echo "$3"
      printf "checksum16 and 0'complement 0x%04x 0x%04x\n" $((sum & 0xffff)) $(((~sum+1) & 0xffff))
    eval $QUIT
  }

  [ -z "$proc" ] && continue

  [[ "$line" =~ ^[\ \t]*# ]] && continue

  line="${line//[$'\t\r\n']}"
  echo -n "$line"
  line="${line//,/ }"
  line="${line//[$'\t\r\n']}"
  hex=($line)
  num=${#hex[@]}

  [ $((num & 1)) -ne 0 ] && { echo -e "\nodd pairs"; eval $QUIT; }

  out=""
  while [ $num -ne 0 ]; do
    val=$((hex[num-1]*0x100+hex[num-2]))
    out="`printf '0x%04x' $val` $out"
    sum=$((sum+val))
    num=$((num-2))
  done
  echo " => $out"

done < "$1"

