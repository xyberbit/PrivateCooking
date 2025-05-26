#!/bin/bash
#
# ssb_tel <user@ip> <pass> <init_cmds|board_name> [serial_port#]
#
# Serial-to-Serial for BMC via Telnet
#
# by xyberbit, use on your own risks, bugs to clark.chang@amperecomputing.com
#
# 06/03/2021 first release

SSB_SELF="$0"
SSB_PORT=2300
SSB_SERN=100
SSB_HOST=${1##*@}
SSB_CORE=ser2net
SSB_EXEC=/tmp/$SSB_CORE

[ -z "$1" ] && {
  i=${0##*/}
  echo -e "usage: $i <user@bmc_ip> <pass> <init_cmds|board_name> [serial_port#]\n"
  [ "${0##*.}" = "sh" ] && [ -e $SSB_CORE.gz ] && cat "$0" $SSB_CORE.gz > ${i%.*}
  exit 1
}

error() {
  echo -e "$1!\n"  
  exit 1
}

echo -n "System validating... "

[ -n "$4" ] && {
  printf "%d" "$4" >&/dev/null || error "serial port# $4 bad"
  SSB_SERN=$(($4))
}

id | grep -q root || error "root required"

for i in sshpass ssh ssh-keygen socat gzip; do
  which $i >&/dev/null || error "executable $i required"
done

shopt -s extglob

case "$3" in
  [Mm][Tt]?(.)[Jj][Aa][Dd][Ee]) # mt.jade
    SSB_BRDN="Mt.Jade"
    SSB_INFO="S0.UART[0,1,4]/S1.UART1"
    SSB_INIT='s=; for i in 0 1 2 3; do gpiotool $((56+i)) --set-data-high; s="$s -C $(('${SSB_PORT}'+i)):raw:0:/dev/ttyS$i:115200"; done; '${SSB_EXEC}' $s'
    ;;
  [Mm][Tt]?(.)[Ss][Nn][Oo][Ww]) # mt.snow
    SSB_BRDN="Mt.Jade"
    SSB_INFO="S0.UART[0,1,4]/S1.UART1"
    SSB_INIT='s=; for i in 0 1 2 3; do gpiotool $((56+i)) --set-data-high; s="$s -C $(('${SSB_PORT}'+i)):raw:0:/dev/ttyS$i:115200"; done; '${SSB_EXEC}' $s'
    ;;
  *)
    SSB_BRDN="UserBoard"
    SSB_INFO="UserPorts"
    SSB_INIT="$3"
    ;;
esac
echo "$SSB_BRDN settings"

# <user@ip> <pass> <cmd>
sshcmd() {
  sshpass -p $2 ssh -q -o StrictHostKeyChecking=no $1 "$3"
}

# <user@ip> <pass> <source> <target>
sshcpx() {
  cat "$3" | sshcmd $1 $2 "cat - > '$4'; chmod 777 '$4'"
}

# <signature> <filepath>
exgzip() {
  local n=`grep -an $1 "$SSB_SELF"`
  [ -z "$n" ] && return 1
  n=${n%%:*}
  tail -n +$((n+1)) "$SSB_SELF" > "$2.gz" || return 1
  gzip -df "$2.gz"
}

echo -n "Remote initializing... "

ssh-keygen -f ~/.ssh/known_hosts -R $SSB_HOST >&/dev/null || error "ssh key bad"
i="id | grep -q root && { killall -q $SSB_CORE; return 0; }"
sshcmd $1 $2 "$i" || error "ssh bad or remote not rooted"
exgzip "#\XYBERBiT" $SSB_EXEC || error "$SSB_CORE creation failed"
echo done

echo -n "Remote configuring... "

sshcpx $1 $2 $SSB_EXEC $SSB_EXEC || error "copy failed"
sshcmd $1 $2 "$SSB_INIT" >&/dev/null || error "execution failed"
SSB_RSET=`sshcmd $1 $2 "ps xo command | grep $SSB_CORE | grep -v grep"`
[ -n "$SSB_RSET" ] && echo "done" || error "execution failed"

echo -n "Device redirecting... "

for i in {0..3}; do
  socat pty,link=/dev/ttyS$((SSB_SERN+i)),raw tcp:$SSB_HOST:$((SSB_PORT+i)) & j=$!
  eval "SSB_PID$i=$j"
done
sleep 1
for i in {0..3}; do
  for j in {3..0}; do
    eval "ps \$SSB_PID$i >&/dev/null" && break
    [ $j -eq 0 ] && error "mapping failed"
    sleep 0.5
  done
done
echo -e "to $SSB_BRDN:$SSB_INFO"

[ -n "$SSB_RSET" ] && echo -e "\nRemote Settings...\n$SSB_RSET"
echo -e "\nLocal Settings...\n`ps xo command | grep socat | grep -v grep`\n"

exit 0
#XYBERBiT
