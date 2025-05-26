#!/bin/bash

# X710 Series EEPROM MAC Address Writer
# clark.chang@amperecomputing.com Nov 2020

# 2020/11/05 initial release, bash guaranteed
# 2020/11/18 validate written MAC and change -q option to -v

# mac: continuous six bytes in hex, or separated between bytes by ".", ":" or "-"
# off: any bash supported formats in bytes

# bash only - universal coding
grep -we "^\(-\|/bin/\)\{0,1\}bash" /proc/$$/cmdline >/dev/null 2>&1 || eval "echo Bash required!; echo; return 99 >/dev/null 2>&1; exit 99"

# essential and misc checks
QUIT="echo; return 1 >&/dev/null; exit 1"
printf "" || eval "echo Printf required!; $QUIT"
MAGIC=0x15728086 # x710 ethtool magic

# information
VERS="0.1"
DATE="2020/11/05"
HELP="Usage: ${0##*/} nic mac[@index] [mac[@index]] ..."
MORE="       where nic=NIC name, mac=6b hexes, index=0..15 or auto"
INFO="Version $VERS $DATE bugs to clark.chang@amperecomputing.com"
RISK="Have fun at your own risk!"

# basic check
[ $# -lt 2 ] && echo -e "$HELP\n$MORE\n$INFO\n$RISK" && eval "$QUIT"
nic=$1; shift

# nic check
vid=`cat /sys/class/net/$nic/device/vendor 2>&1`; ret=$?
did=`cat /sys/class/net/$nic/device/device 2>&1`; ret=$((ret | $?))
[ $ret -ne 0 ] && eval "echo Bad nic \'$nic\'!; $QUIT"
[ $MAGIC = $did${vid/0x/} ] || eval "echo "Bad id \'${vid/0x/}:${did/0x/}\'!"; $QUIT"

# validate arguments
macs=; idxs=; idx=0
for arg in $@; do
    while [ 1 ]; do # easy error control
        err="$arg"
        # index
        i="${arg##*@}"
        [ "$i" = "$arg" ] && i=$idx # auto order
        i=`printf "%d" $i 2>&1` || break # number?
        echo "$idxs" | grep -iq " $i " && break # existing?
        [ $i -lt 0 -o $i -gt 15 ] && break # range 0..15?
        idxs="$idxs $i " # add to index list
        idx=$((idx+1)) # auto increment
        # mac
        m=${arg%%@*}
        m=${m// .,:-/} # separators
        [ ${#m} -ne 12 ] && break # 6 bytes
        echo "$m" | grep -iq "[^0-9a-f]" && break # hex?
        macs="$macs $m@$i " # add to mac list
        err=; break
    done
    [ -n "$err" ] && eval "echo Bad argument \'$err\'!; $QUIT"
done

# sum big-endian word string, $1=data hex string
smws() {
    local s=0 i=0 j=${#1}
    while [ $i -lt $j ]; do
        s=$((s+0x${1:i+2:2}${1:i:2}))
        i=$((i+4))
    done
    echo $s
}

# eeprom read byte string, $1=offset in bytes, $2=length up to 16, o/p=data hex string
eers() {
    local s=`ethtool -e $nic offset $1 length $2`
    s=`echo "$s" | grep :`
    s="${s//0x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]:/}"
    printf "%s\n" ${s// /} # removed all blanks
}

# eeprom read big-endian word, $1=offset in words, o/p=data word
eerw() {
    local w=`eers $(($1*2)) 2`
    echo "0x${w:2}${w:0:2}"
}

# eeprom write byte, $1=offset in bytes, $2=data byte
eewb() {
    ethtool -E $nic magic $MAGIC offset $1 value $2
}

# eeprom write big-endian word, $1=offset in words, $2=data word
eeww() {
    local i=$(($1*2))
    eewb $i $(($2 & 0xff))
    eewb $((i+1)) $(($2 >> 8))
}	

# eeprom write byte string, $1=offset in bytes, $2=data hex string
eews() {
    local i=0 j=$((${#2}/2))
    while [ $i -lt $j ]; do
        eewb $(($1+i)) 0x${2:$((i*2)):2}
        i=$((i+1))
    done
}

# preparing to write X710
NVM_CTRL=0x0249   # 1st word in NVM
NVM_CKS_IDX=0x3F  # NVM checksum
EMP_SR_IDX=0x48   # pointer to EMP SR settings
EMP_SR_HDR=0x002b # length could be different in future, don't check
PF_MAC_IDX=0x18   # offset to PF MAC address
PF_MAC_HDR=0x0040 # PF MAC length
VPD_IDX=0x2F      # pointer to VPD module
PCIE_ALT_IDX=0x3E # pointer to PCIe Alt Auto Load module

# NVM header and checksum
[ `eerw 0`= $NVM_CTRL ] || eval "echo Bad NVM!; $QUIT"
checksum=`eerw $NVM_CKS_IDX`

# MAC offset -> NVM(0x48) => EMP_SR(0x18) => PF_MAC
emp_sr_bas=`eerw $EMP_SR_IDX`
pf_mac_ofs=`eerw $((emp_sr_base+PF_MAC_IDX))`
pf_mac_bas=$((pf_mac_ofs+emp_sr_base+PF_MAC_IDX))

# MAC header
[ eerw $pf_mac_bas` = $PF_MAC_HDR ] || eval "echo Bad MAC section!; $QUIT"

# checksum
cksum=`eerw $NVM_CKS_IDX`

for mi in $macs; do
    p=$(( (pf_mac_bas+1+${mi##*@}*4)*2 )) # mac location
    cksum=$((cksum-$(sm_ws `eers $p 6`))) # deduct original mac portion from checksum
    eews $((p*2)) ${mi%%@*} # write mac
    mac=`eers $((p*2)) 6` # read mac
    cksum=$((cksum+`sm_ws $mac`)) # add updated mac portion to checksum
    echo "$mac" | grep -iq $mac || eval "echo Failed to write!; $QUIT"
done

echo; return 0 >&/dev/null; exit 0
