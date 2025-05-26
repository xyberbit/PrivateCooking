#!/bin/bash

# Ethernet EEPROM MAC Writer
# clark.chang@amperecomputing.com Dec 2020

# 2020/10/28 initial release, bash guaranteed
# 2020/11/02 validate written MAC and change -q option to -v
# 2020/12/25 optimized a bit

# mac: continuous six bytes in hex, or separated between bytes by ".", ":" or "-"
# off: any bash supported formats in bytes

# Intel Series MAC offsets
# 82574 0x000
# i210  0x000
# i350  0x000 0x100 0x180 0x200

# bash only - universal coding
grep -we "^\(-\|/bin/\)\{0,1\}bash" /proc/$$/cmdline >/dev/null 2>&1 || eval "echo Unsupported environment!; echo; return 99 >/dev/null 2>&1; exit 99"

# essential
QUIT="echo; return 1 >&/dev/null; exit 1"
verbose=0
which ethtool >&/dev/null || eval "echo 'Ethtool required!'; $QUIT"

# information
VERS="0.21"
DATE="12/25/2020"
HELP="Usage: ${0##*/} [-v] nic mac@off [mac@off] ..."
INFO="Ethernet EEPROM MAC Writer, version $VERS $DATE"
RISK="Use your own risk, bugs to clark.chang@amperecomputing.com"

# basic check
[ $# -lt 2 ] && echo -e "$HELP\n$INFO\n$RISK" && eval "$QUIT"
[ $1 = -v ] && verbose=1 && shift
nic=$1; shift

# nic check and magic build
vid=`cat /sys/class/net/$nic/device/vendor 2>&1`; vret=$?
did=`cat /sys/class/net/$nic/device/device 2>&1`; dret=$?
[ $vret -ne 0 -o $dret -ne 0 ] && echo "Bad nic \"$nic\"!" && eval "$QUIT"
magic=$did${vid/0x/}

# parse rest parameters
for arg in $@; do
    [ "$arg" = "-v" ] && verbose=1 && continue
    ofs=${arg##*@}
    mac=${arg%%@*}
    [ ${#mac} -gt 12 ] && mac=${mac//./}
    [ ${#mac} -gt 12 ] && mac=${mac//:/}
    [ ${#mac} -gt 12 ] && mac=${mac//-/}
    [ ${#mac} -ne 12 ] && echo "Bad argumnet \"$arg\"!" && eval "$QUER"
    for i in {0..5}; do
        ethtool -E $nic magic $magic offset $((ofs+i)) value 0x${mac:$((i*2)):2}
        [ $? -ne 0 ] && eval "$QUIT"
    done
    eep=`ethtool -e $nic offset $((ofs)) length 6`
    [ $verbose -eq 1 ] && echo "$eep"
    eep=`echo $eep | grep :`
    eep=${eep##*:}
    echo ${eep// /} | grep -iq $mac || eval "echo 'Failed to write!'; $QUIT"
done

echo; return 0 >&/dev/null; exit 0
