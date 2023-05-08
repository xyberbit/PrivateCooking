#!/bin/bash

# 0.10 2021/11/13 initial version
# 0.11 2022/06/23 helps improvement
# 0.12 2022/06/30 offset and file size validation
# 0.13 2022/08/31 hex read improvement and fix, better aligned output
# 0.14 2022/09/01 light read support, read data validation, original data displayed when write
# TODO group mods supported

VER="0.14"
BLD="2022/09/01"

EXIT="return $RET >&/dev/null; exit $RET"
EXOK="RET=0; $EXIT"
EXER="RET=1; $EXIT"
TMPF=/tmp/_nvpmod
#DBG=1

errpr() {
  echo -e "ERR: $1!\n"
}

dbgpr() {
  [ -n "$DBG" ] && echo "DBG: $1"
}

# $1=image
# $2=index
# $3=[data]

[ $# -eq 0 ] && {
  echo "NVParam Image Modifier for Altra Family $VER"
  echo "Build $BLD, bugs to clark.chang@amperecomputing.com"
  echo "usage: ${0##*/} file index|offset [data]"
  echo "  file    ROM image with NV parameters, types SPI, ATF and CFG supported" 
  echo "  index   Ampere NVP index (0x0000..0xffff) & ~7"
  echo "  offset  Full ROM offset (0x110000..0x11bfff) & ~7, (0x5f0000..0x5f3fff) & ~7"
  echo "  data    32-bit data"
  echo
  eval "$EXER"
}
[ $# -lt 2 ] && {
  errpr "Too few arguments"
  eval "$EXER"
}

# $1=file, $2=offset, $3=length
hexrd() {
  local d i=0
  while [ $i -lt $3 ]; do
    dd if="$1" bs=1 count=1 skip=$(($2+i)) 2>/dev/null > $TMPF
    read -n 1 d < $TMPF
    [ ${#d} -eq 0 ] && echo -n 00 || printf "%02x" \'$d
    i=$((i+1))
  done
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

# identify image type
# 0xffffffffffff@0 = SPI
# AMPC@0           = ATF
# 0xff80@4         = CFG

[ -e "$1" ] || { errpr "'$1' not existing"; eval "$EXER"; }
len=`stat -c %s "$1"`
echo "INF: size   0x`printf %x $len` ($len)" 
hex=`hexrd "$1" 0 6`
echo "INF: header 0x$hex"

if [ $hex = ffffffffffff ]; then
  bs1=0x110000
  bs2=0x5f0000
  echo "INF: type   SPI"
elif [ ${hex:0:8} = 414d5043 ]; then
  bs1=
  bs2=0x1f0000
  echo "INF: type   ATF"
elif [ ${hex:8:4} = ff80 ]; then
  bs1=
  bs2=0
  echo "INF: type   CFG (Board Settings)"
else
  errpr "'$1' invalid"; eval "$EXER"
fi
dbgpr "Base1 $bs1, Base2 $bs2"

[ $(($2 & 0x7)) -eq 0 ] && off=$(($2)) || { errpr "'$2' invalid"; eval "$EXER"; }
[ $off -ge $((0x5f0000)) ] && off=$((off-0x5f0000+0xc000))
[ $off -ge $((0x110000)) ] && off=$((off-0x110000))
[ $off -gt $((0xffff))   ] && { errpr "'$2' invalid"; eval "$EXER"; }
printf "INF: index  0x%04x\n" $off

if [ $off -lt $((0xc000)) ]; then
  [ -z "$bs1" ] && { errpr "'$1' or '$2' invalid"; eval "$EXER"; }
  off=$((bs1 + off)) 
  att="0xff 0xff"
else
  off=$((bs2 + off - 0xc000))
  att="0xff 0x80"
fi
[ $((off+8)) -gt $len ] && { errpr "0x`printf %x $off` converted from '$2' over offset"; eval "$EXER"; }
printf "INF: offset 0x%04x\n" $off

hex=`hexrd "$1" $off 8`
dbgpr "hex $hex"
dat0=0x${hex:0:2}
dat1=0x${hex:2:2}
dat2=0x${hex:4:2}
dat3=0x${hex:6:2}
aclr=0x${hex:8:2}
aclw=0x${hex:10:2}
crcx=0x${hex:14:2}${hex:12:2}
echo -n "INF: read   $dat3${dat2/0x/}${dat1/0x/}${dat0/0x/} $aclr $aclw $crcx ("
[ $((crcx)) -ne `crc16 "$dat0 $dat1 $dat2 $dat3 $aclr $aclw 0 0"` ] && echo -n "in"
echo "valid)"

if [ -n "$3" ]; then
  bin=
  for i in `nvgen $(($3 & 0xffffffff)) "$att"`; do
    bin="$bin `printf 0x%02x $i`"
  done
  echo -n "INF: write  ${bin:1}"
  if [ -n "$DBG" ]; then
    echo " (dry run)"
  else
    echo
    echo -en "${bin// 0/\\}" | dd bs=1 seek=$((off)) conv=notrunc of="$1" &>/dev/null
  fi
fi
echo

eval "$EXOK"
