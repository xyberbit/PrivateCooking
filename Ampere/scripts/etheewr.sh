#!/bin/bash

# Ethernet EEPROM Hex String Writer
# clark.chang@amperecomputing.com Nov 2020

# 2020/10/28 initial release, bash guaranteed
# 2020/11/16 turned into generic hex string writer

# hexes:  continueous (up to 16) two-digit hex string whcih can be separated by space, ".", ":" or "-"
# offset: any bash supported formats in bytes

# Intel Series MAC offsets
# 82574 0x000
# i210  0x000
# i350  0x000 0x100 0x180 0x200

# bash only - universal coding
grep -we "^\(-\|/bin/\)\{0,1\}bash" /proc/$$/cmdline >/dev/null 2>&1 || eval "echo Bash required!; echo; return 99 >/dev/null 2>&1; exit 99"

# essential
QUIT="echo; return 1 >&/dev/null; exit 1"
printf "" >&/dev/null || eval "echo Printf required!; $QUIT"
quiet=0

# information
VERS="0.3"
DATE="2020/11/16"
HELP="Usage: ${0##*/} [-q] nic hexes@offset [hexes@offset] ..."
INFO="Version $VERS $DATE bugs to clark.chang@amperecomputing.com"
RISK="Have fun at your own risk!"

# basic check
[ $# -lt 2 ] && eval "echo -e "$HELP\n$INFO\n$RISK; $QUIT"
[ $1 = -q ] && quiet=1 && shift
nic=$1; shift

# nic check and magic build
vid=`cat /sys/class/net/$nic/device/vendor 2>&1`; vret=$?
did=`cat /sys/class/net/$nic/device/device 2>&1`; dret=$?
[ $vret -ne 0 -o $dret -ne 0 ] && eval "Bad nic \"$nic\"!; $QUIT"
magic=$did${vid/0x/}

# parse rest parameters
for arg in $@; do
    [ "$arg" = "-q" ] && quiet=1 && continue
    ofs=`printf "0x%04x" "${arg##*@}" 2>&1` || eval "echo Bad offset \"$arg\"!; $QUIT"
    hex=${arg%%@*}
    hex=${hex//./ }
    hex=${hex//:/ }
    hex=${hex//-/ }
    for i in $hex; do
        [ echo "$i" | grep "[^0-9a-fA-F]" >&/dev/null -o $((${#i} & 1)) -ne 0 ] &&
            eval "echo Bad hexes \"$arg\"!; $QUIT"
    done
    hex=${hex// /}
    len=$((${#hex}/2))
    [ $len -gt 16 ] && eval "echo 16 hexes max \"$arg\"!; $QUIT"
    i=0
    while [ $i -lt  $len ]; do
        ethtool -E $nic magic $magic offset $((ofs+i)) value 0x${hex:$((i*2)):2}
        [ $? -ne 0 ] && eval "echo Bad write!; $QUIT"
        i=$((i+1))
    done
    eep=`ethtool -e $nic offset $((ofs)) length $len
    [ $quiet -eq 0 ] && echo "$eep"
    eep=`echo $eep | grep :`
    eep=${eep##*:}
    echo ${eep// /} | grep -iq $hex || eval "echo Bad write at \"$ofs\"!; $QUIT"
done

echo; return 0 >&/dev/null; exit 0
