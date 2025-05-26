#!/bin/bash
#
# Ampere Mt.Snow CPLD Flasher
#   clark.chang@amperecomputing.com

user="sysadmin"
pass="superuser"
ussh="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" # unattended ssh
ERRC=105

pidcmd="`cat -v /proc/$$/cmdline`"
pidcmd="${pidcmd/$0/}"
[ ${#pidcmd} -le 2 ] && echo "Source unsupported!" && return 254

[ $# -ne 2 ] && echo "Usage: ${0##*\/} <BMC IP> <CPLD .rcu>" && exit $ERRC

ping -c 1 -w 2 "$1" >&/dev/null
[ $? -ne 0 ] && echo "Invalid IP \"$1\" or not responded!" && exit $ERRC

[ ! -e "$2" ] && echo "\"$2\" not existing!" && exit $ERRC
[ -n "${2%%*.rcu}" ] && echo "\"$2\" not .rcu!" && exit $ERRC

sshpass -p $pass rsync -e "$ussh" "$2" $user@$1:/tmp 2>/dev/null
sshpass -p $pass $ussh -t $user@$1 "cpld_update --mb_cpld --ipmi '/tmp/${2##*\/}'" 2>/dev/null
