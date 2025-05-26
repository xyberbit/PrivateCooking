#!/bin/bash

# AST2500 MDIO tool (working with other series if MDIO regsiters comptaible)
# clark.chang@amperecomputing.com Dec 2020

# 2020/07/29 initial release, source prevention
# 2020/08/26 mask and shift supported; debugging messages removed, try "bash -x"
# 2020/08/27 bus assigned in argument 1 (was determined by last char of $0); disabling NIC prevents from mdio conflict
# 2020/09/30 down associated bond NIC and printk level to 1 to suppress messages
# 2020/10/05 multiple read/writes supported to form a complete setting sequence
# 2020/12/25 optimized a bit

# source mode not permitted
[ "`cat /proc/$$/cmdline | xargs -0 echo`" = "$0" ] && eval 'echo "Source mode prohibited!"; echo; return 1 >&/dev/null; exit 99'

[ -z "`id | grep 'uid=0('`" ] && echo "root privilege requried!" && exit 98

reqchk() {
	which $1 >&/dev/null || echo "$1 required!" && exit 98
}
reqchk printf
reqchk devmem

VERS="0.125"
DATE="12/25/2020"
HELP="Usage: ${0##*/} bus:nic[:phy] rw [rw]...; where rw= reg[:data[:mask[:shift]]]"
INFO="AST2500 MDIO Tool, Version $VERS $DATE "
RISK="Use at your own risk, bugs to clark.chang@amperecomputing.com"

[ $# -lt 2 ] && echo -e "$HELP\n$INFO\n$RISK" && exit 97

AST_MAC60_MASK=0xf000ffff
AST_MAC60_RBIT=0x04000000 # $((1 << 26))
AST_MAC60_WBIT=0x08000000 # $((1 << 27))

MMD_ACR_REG=0x0d
MMD_ADR_REG=0x0e
MMD_ACR_NOINC=0x4000

pkpath="/proc/sys/kernel/printk"

# bus:nic[:phy]
bus="${1%%:*}"; a="${1/$bus/}"; a="${a/:/}"
bus=`printf "%d" $bus 2>&1`; [ $? -ne 0 ] && echo "bad argument \"$1\"!" && exit 97
[ $bus -lt 1 -o $bus -gt 2 ] && echo "bad bus \"$bus\"!" && exit 97

nic="${a%%:*}"; a="${a/$nic/}"
[ -z "$nic" ] && echo "empty nic!" && exit 97
nstat="`ip a s $nic 2>&1`"; [ $? -ne 0 ] && echo "bad nic \"$nic\"!" && exit 97
[ -z "`echo $nstat | grep ',UP'`" ] && nic=

phy="${a//:/}"; [ -z "$phy" ] && phy=0
phy=`printf "%d" $phy 2>&1`; [ $? -ne 0 ] && echo "bad argument \"$1\"!" && exit 97
[ $phy -ge 32 ] && echo "bad phy \"$phy\"!" && exit 97

AST_MAC60A_REG=$((0x1e640060 + bus*0x20000))
AST_MAC64A_REG=$((AST_MAC60A_REG + 4))

mac60d=$((`devmem $AST_MAC60A_REG 32` & AST_MAC60_MASK))

# $1=reg [$2=data]
phyrw() {
    local b=$AST_MAC60_RBIT
    local r=$(($1 & 0x1f))

    [ -n "$2" ] && b=$AST_MAC60_WBIT && devmem $AST_MAC64A_REG 32 $(($2 & 0xffff))

    local d60=$((b | r<<21 | phy<<16 | mac60d))
    devmem $AST_MAC60A_REG 32 $d60

    until [ $((d60 & b)) -eq 0 ]; do
        d60=`devmem $AST_MAC60A_REG 32`
    done
    [ "$b" = "$AST_MAC60_RBIT" ] && printf "0x%04x" $((`devmem $AST_MAC64A_REG 32`>>16))
}

# $1=reg [$2=data [$3=mask [$4=shift]]]
phyx() {
    [ -n "$5" ] && return 1
    data="$2"
    if [ -n "$3" ]; then
        # only mask : (reg & ~ mask)           |  (data & mask)
        # with shift: (reg & ~(mask << shift)) | ((data & mask) << shift)
        data=$((data & $3))
        datr=`phyrw $1`
        [ -z "$4" ] && data=$((data | (datr&~$3))) || data=$((data<<$4 | (datr&~($3<<$4))))
    fi
    phyrw $1 $data # data null for read
    [ -z "$data" ] && echo
    return 0
}

# change printk
pk="`cat $pkpath`"
echo 1 > $pkpath

# down bond to suppress console messages
bond=
if [ -n "$nic" -a -n "`echo $nstat | grep bond`" ]; then
    i=0
    until [ $i -gt 9 ]; do
        [ -n "`echo $nstat | grep bond$i`" ] && bond="bond$i" && break
        i=$((i+1))
    done
    [ -n "$bond" -a -z "`ip a s $bond | grep ',UP'`" ] && bond=
fi

[ -n "$bond" ] && ip l s $bond down >&/dev/null
[ -n "$nic"  ] && ip l s $nic  down >&/dev/null

# function replaces array for tiny bash
for i in ${@#* }; do
    arg="$i"
    n="${i//:/ }"
    f=`printf "%%d %.0s" $n`
    n=`printf "$f" $n 2>&1`
    [ $? -ne 0 ] && break
    phyx $n
    [ $? -ne 0 ] && break
    arg=
done

[ -n "$nic"  ] && ip l s $nic  up >&/dev/null
[ -n "$bond" ] && ip l s $bond up >&/dev/null

echo "$pk" > $pkpath

[ -z "$arg" ] && exit 0
echo "bad argument \"$arg\"!"
exit 1
