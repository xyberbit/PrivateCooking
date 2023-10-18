#
# environment
#
dmesg -n 1
killall timeoutd
alias ll="ls -l"
alias i=ipmi
alias g=gpio
alias p=prog

#
# ipmitool
#
ipmi() {
  local cmd opt
  [ $# = 0 ] && return 0
  [ $# = 1 ] && {
    echo $1 | grep -iq on && cmd="power on"
    echo $1 | grep -iq of && cmd="power off"
    echo $1 | grep -iq so && cmd="power soft"
    echo $1 | grep -iq re && cmd="power reset"
    echo $1 | grep -iq st && cmd="power status"
    echo $1 | grep -iq bi && cmd="chassis bootdev bios"
    echo $1 | grep -iq cd && cmd="chassis bootdev cdrom"
    echo $1 | grep -iq di && cmd="chassis bootdev disk"  
    echo $1 | grep -iq cm && opt="clear-cmos=yes"
    echo "$cmd" | grep -q bootdev && cmd="$cmd $opt"
  }
  [ -z "$cmd" ] && cmd="$@"
  ipmitool -H 127.0.0.1 -U admin -P admin $cmd
}

#
# sol optimization
#
i sol set character-accumulate-level 10
i sol set character-send-threshold 32
i sol set retry-interval 10

#
# gpio <bus>     [bmc|cpu] # flash bus  selection
# gpio <spi|eep> [pri|sec] # flash chip selection
# gpio <cpl>     [dis|ena] # CPLD programming enabled/disabled
# gpio <atx>     [on|off]  # ATX PSU on/off
#
gpio() {
  local pin cmd hi lo
  echo "$@" | grep -iq bus && pin=226 && lo=BMC && hi=CPU
  echo "$@" | grep -iq spi && pin=227 && lo=PRI && hi=SEC
  echo "$@" | grep -iq eep && pin=8   && lo=SEC && hi=PRI
  echo "$@" | grep -iq cpl && pin=98  && lo=DIS && hi=ENA
  echo "$@" | grep -iq atx && pin=42  && lo=ON  && hi=OFF
  if [ -z "$pin" ]; then
    gpiotool $@
  else
    echo "$@" | grep -iq $hi && cmd=high
    echo "$@" | grep -iq $lo && cmd=low
    if [ -z "$cmd" ]; then
      cmd="`gpiotool $pin --get-data`"
    else
      cmd="`gpiotool $pin --set-data-$cmd`"
    fi
    echo -n $cmd
    echo -n " ==> $pin"
    echo "$cmd" | grep -iq "low" && echo "($lo)" || echo "($hi)"
  fi
}

#
# prog *.<slim|spi|img|0xff>
#
prog() {
  local opt
  case "${1##*.}" in
    slim) opt="-c 2 -b 1 -s 0x50";;
     spi) opt="-c 1";;
     img) opt="-c 1 -o 0x400000";;
    0xff) # todo: support erasing other partitions
      set - /tmp/4m.0xff; opt="-c 1"
      b=`echo -en "\xff"`; for i in 0 1 2 3 4 5 6 7 8 9; do b="$b$b"; done # 2^10=1K
      echo -n "$b" >>$1; dd if=$1 of=$1 seek=1 bs=1K count=$((1024*4-1));; # 1K*4K=4M
  esac
  [ -n "$opt" ] || return -1
  echo yn >/tmp/yn
  amp_hostfw_update $opt -f "$1" </tmp/yn
}
