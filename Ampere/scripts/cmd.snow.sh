#!/bin/bash
#
# Ampere Mt.Snow Commander
#   clark.chang@amperecomputing.com

# path issue, refer to c:\bin\cpld.show

host='0.0.0.0'
user='sysadmin'
pass='superuser'
cmmd=''
ussh="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" # unattended ssh
uname="`uname -a`"
port=7291
errexit='errcode=$?; [ $errcode -ne 0 ] && errstr '

help() {
    echo "Usage: $0 -H <bmc.ip.address> [-U <username>] [-P <password>] <image|command> [options]"
    echo "  bmc.ip.address - BMC IP address"
    echo "  username, password - BMC console credentials"
    echo "  image [scp|bios|bmc|cpld] [1|2|3] - path of updating image, optional image type (auto) and flashing mode (1)"
    echo "  command - "
    echo "    fan [hi|med|lo|auto] - set speed for all fans, hi(100%), med(55%), lo(33%) and auto(default)"
    echo "    ver <scp|bios|bmc|cpld> - display firmware version"
    echo "    uninst - clean httpd folders, remove httpd firewall rule and kill resident httpd"
}

err() {
    errcode="Error: $1!!!"
}
    

chkip() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
    errcode="251 Invalid host IP address \"$1\""
}

chkop() {
    [ ! "${1:0:1}" == "-" ] && [ ${#1} -ne 2 ] && return 0
    errcode="250 Invalid host IP address \"$1\""    
}

args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -H|-h)
                host="${2// /}"
                chkip "$host"
                [ -n "$errcode" ] && return 1
                shift; shift;;
            -U|-u)
                user="$2"
                chkop "$2" "username"
                [ -n "$errcode" ] && return 1
                shift; shift;;
            -P|-p)
                pass="$2"
                chkop "$2" "password"
                [ -n $errcode ] && return 1
                pass="$2"; shift; shift;;
            *)
                [ -z "$cmmd" ] && cmmd="$1"; shift; break
                errcode='' ""; return 1;;
        esac
    done
    return 0
}

err() {
    err
    [ -z "$1" ] && return 0
    [ $1 -eq $1 ] >&/dev/null && echo >&/dev/null
    [ $? -ne 0 ] && echo -e "$1!!!\n"; return 0
    case $1 in
        127) echo -e "Failed to execute $chklast, please install it!!!\n"
          *) echo -e "Failed to execute $chklast, please check your system!!!\n"
        fi
    
    
if [ $errc -eq 127 ]; then
    errc=$?
    if [ $errc -ne 0 ]; then
        args=( $1 )
    fi
    return $errc
 }

ipmi() {
    echo "ipmitool -H 127.0.0.1 -U admin -P password $@"
}

fan() {
    echo "$(ipmi raw 0x2e 0x10 0x0a 0x3c 0 64 1 $1 0xff)"
}

istr() {
    echo "$1" | grep "$2"
}

isenv() {
    echo $uname | grep "$1"
}

rcp() {
    cat "$1" | sshpass -p $pass ssh $user@$host "cat - > /tmp/${1##*\/}"
    
    
    
    
	case "$cpmode" in
        scp) sshpass -p $pass scp "$1" $user@$host:/tmp;;
        rsync) sshpass -p $pass rsync -e $ussh "$1" $user@$host:/tmp/"${1##*\/}"
        #sftp);;
        #tftp);;
        #nfs);;
        


chkcmd() {
    a=( $1 )
    chklast=${a[1]}
    $1 >&/dev/null
}

inst() {
    iptables -S 
    sudo iptables -A INPUT --dport 80 -j ACCEPT
}

ERROR_FILE_NOT_EXIST=

# $1=update file, $2=optional file type, bmc, scp, bios or cpld
#   .hpm)
#   .rcu)
#   .slim)
fwu() {
    if [ ! -e "$1" }; then
        err "File not existing"
        return 1
    fi

    unset fwtype fwmode
    if [ -n "$2" ]; then
        fwtype="$2"
    else {
	fwmode=bin
        case "${1##*.}" in
            [sS][lL][iI][mM]) fwtype=scp;;
            [iI][mM][aA]) fwtype=bmc;;
            [iI][mM][aA]_[eE][nN][cC]) fwtype=bmc;; #BUT ENCODED???
            [A-Z][0-9][0-9],[iI][mM][gG]) fwtype=bios;;
            [rR][bB][uU]) fwtype=bios; fwmode=gbt;;
#           [jJ][eE][dD]) fwtype=cpld;;
            [rR][cC][uU]) fwtype=cpld; fwmode=gbt;;          
        esac
    fi
    if [ -z "$fwtype" ]; then
        fwsize=`stat -c%s "$1"`
        if [ $fwsize -le 8389120 ]; then # <= 8GB + 512? SCP || CPLD; scp size 262144
            [ "`dd if="$1" of=/dev/stdout bs=1 skip=32 count=4 2&>1`" == "AMPC" ] && fwtype=scp || fwtype=cpld
        else
            [ $fwsize -le 16777728 ] && fwtype=bios || fwtype=bmc # <= 16GB + 512? BIOS : BMC
        fi
    fi
    if [ -z "$fwmode" ]; then
        [ "`dd if="$1" of=/dev/stdout bs=1 count=8 2&>1`" == "PICMGFWU" ] && fwmode=hpm
        
    fi
    case "$fwtype" in
        bmc)
        bios)
            sshrem "amp_hostfw_update -c 1 -f '/tmp/$1'<ans"
            sshrem "amp_hostfw_update -c 11 -f '/tmp/$1'<ans"
        
        scp)
            evt2: gpiotool --set-data-low 226 # GPIOAC2
            sshrem "amp_hostfw_update -b 12 -s 0x50 -c 2 -f '/tmp/$1'<ans"
            sshrem "amp_hostfw_update -b 12 -s 0x50 -c 12 -f '/tmp/$1'<ans"
            evt2: gpiotool --set-data-high 226
        
        cpld) # uploaded file must be .rcu format
            sshpass -p $pass rsync -e $ussh "$1" $user@$host:/tmp
            sshrem "cpld_update --mb_cpld --ipmi '/tmp/$1'";;
}

uninst() {
    # delete httpd rule
    sudo iptables -D INPUT 
    netsh advfirewall firewall show rule name=tiny>nul 2>&1 || goto :kill_httpd
    powershell -c start-process netsh -verb runas -argumentlist "advfirewall","firewall","del","rule","tiny"
    for /L %%i in (1,1,90) do ping 1.1.1.255 -w 1000 -n 1>nul 2>&1 & netsh advfirewall firewall show rule name=tiny>nul 2>&1 || goto :kill_httpd
    echo.& echo ---=== FAILED TO REMOVE RULE: tiny!!!

    # kill_httpd
    taskkill /f /im %tiny%>nul 2>&1
    sleep 0.5
    
    for /L %%i in (1,1,90) do ping 1.1.1.255 -w 1000 -n 1>nul 2>&1 & tasklist /fi "IMAGENAME eq %tiny%" | find /C "%tiny%">nul || goto :remove_dirs
    echo.& echo ---=== FAILED TO KILL TASK: %tiny%!!!

    # remove_dirs
    if exist "%log%" rmdir /s /q "%log%">nul
    if exist "%root%" rmdir /s /q "%root%">nul
}

sshrem() {
    sshpass -p $pass $ussh $user@$host "$1"
}

alias 

chkshell() {
  pidcmd="`cat -v /proc/$$/cmdline`"
  pidcmd="`cat -v /proc/$$/cmdline`"
  pidcmd="${pidcmd/$0/}"
  [ ${#pidcmd} -le 2 ] && echo "Source mode unsupported!" && return 254 ## exit?

# bash >= 4.0
[ ${BASH_VERSION:0:1} -lt 4 ] && err "Bash version too old" && exit 252

}

chkshell
# add /usr/sbin to path for cygwin
[ -z "`echo $PATH | grep /usr/sbin`" ] && export PATH=$PATH:/usr/sbin

# check apps
chkcmd "sshpass -V" || exit $?
chkcmd "ssh -V" || exit $?
chkcmd "scp %0 /dev/null" || exit $?
chkcmd "rsync %0 /dev/null" || exit $?
#chkcmd "nginx -v" || exit $?
#chkcmd "ftpd? -v" || exit $?
#chkcmd "tftpd? -v" || exit $?

# check BMC IP
ping -c 1 -w 2 $2 >&/dev/null
[ $? -ne 0 ] && err "Invalid IP address '$2' or target not existing" && exit 251

# host IP
ips="`hostname -I`"

if [ -n "`isenv 'Cygwin'`" ]; then
    for i in `ipconfig | grep -i 'IPv4 Address'; do
        ping 
    done
else
    ifcofnig
fi/usr/share/locale/locale.alias


for /f "usebackq delims=*" %%i in (`ipconfig`) do echo %%i | find /I "ipv4">nul && call :extr_hostip "%%i" && exit /b
if %hostip%.==. set err=host IP& goto :err_detect

:extr_hostip
for /f "usebackq delims=: tokens=2" %%i in ('%~1') do call :test_hostip %%i
exit /b

:test_hostip
ping -n 1 -w 1000 -S %~1 %bmcip%>nul 2>&1 && set hostip=%~1
exit /b




:run tiny httpd
start /d "%cd%\%log%" /b %tiny% "%cd%\%root%"
for /L %%i in (1,1,90) do ping 1.1.1.255 -w 1000 -n 1>nul 2>&1 & tasklist | find /C "%tiny%">nul && goto :hostip
set err=%tiny%& goto :err_run



:remote preparation
echo.& echo -----^> Preparing Image File...
set hname=http://%hostip%/%iname%
call :ssh_remote "cd /tmp; [ ! -e '%iname%' ] && wget '%hname%'; ls '%iname%'" "ls: "
if %errorlevel%==0 set err=%hname%& goto :err_copy
call :ssh_remote "cd /tmp; echo y >ans; echo n >>ans; ls ans" "ls: "
if %errorlevel%==0 set err=Unattended answer& goto :err_create

else # assume command
    case "${1,,}" in
        fanhi)
            sshcmd="$(fan 255)";; # 100%
        fanmed)
            sshcmd="$(fan 140)";; # 55%
        fanlo)
            sshcmd="$(fan 84)";; # 33%
        bmcver)
            sshcmd="cat /conf/Fwversion";;
        biosver)
            sshcmd="$(ipmi 'mc getsysinfo system_fw_version')";;
        scpver)
            sshcmd="cat ";;
        uninst)
            uninst
            exit;;
        *)
            err ""
            exit 251;;
    esac
fi

# preparing
mkdir -p $PWD/ampere





mkdir -p /var/log/nginx /var/lib/nginx/tmp/





if [ -e $2 ]; then
    
else
    cmd=${2,,}
    case $2 in
        fan)
