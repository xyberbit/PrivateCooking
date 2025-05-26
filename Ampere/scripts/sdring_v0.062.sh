#!/bin/sh

BAN="IPMI Sensors Data Reading" 
VER="v0.062 - Dec 11, 2018"

# SDRing Features:
# 1. sensors reading - v0.01
# 2. reading average calculation - v0.01
# 3. aligned output - v0.01
# 4. user defined formula calculation - v0.03
# 5. compatible with AMI BMC shell (bmc sh -> no ++, (()), array...) - v0.05
# 6. output to logfile - v0.05
# 7. minimum external commands (ipmitool and awk) - v0.05
# 8. sensor id with space supported - v0.06, fixed when sourced - v0.061, better help - v0.062

# Regular Examples
# CPU - ./sdring -S CPU_Temp/ -S CPU_Power/ -S MEM_Power/ -F CPU_Power+MEM_Power/4.5/
# BMC - ./sdring -U ADMIN -P ADMIN -S CPU_Temp/ -S CPU_Power/ -S MEM_Power/ -F CPU_Power+MEM_Power/4.5/
# RPC - ./sdring -H 192.168.9.11 -U ADMIN -P ADMIN -S CPU_Temp/ -S CPU_Power/ -S MEM_Power/ -F CPU_Power+MEM_Power/4.5/

# Simulation Examples
# CPU - ./sdring -S "CPU Temp/" -S "CPU Power/" -S MEM_Power/ -F "CPU Power+MEM_Power/4.5/"
# BMC - ./sdring -U ADMIN -P ADMIN -S "CPU Temp/" -S "CPU Power/" -S MEM_Power/ -F "CPU Power+MEM_Power/4.5/"
# RPC - ./sdring -H 192.168.9.11 -U ADMIN -P ADMIN -S "CPU Temp/" -S "CPU Power/" -S MEM_Power/ -F "CPU Power+MEM_Power/4.5/"

# TODO
# Check duplicate sensor ids
# Adavanced average calculation, says of last n readings instead of all


### CONSTANTS

AG0="$0"
ERR="Error:"
SPC="  "
DEC=3
LIN=10
DBG=0
SID="CPU_Temp CPU_Power MEM_Power" #sim: non-space id list
SYM="" #sim: symbol to be replaced by space
unset AWK IPMITOOL


### EVAL MACROS

HPX="return 1 2>/dev/null; exit 1"
ERX="return 2 2>/dev/null; exit 2"


### FUNCTIONS

db() {
  [ $DBG -ne 0 ] && echo "Debug:-$1-:"
}

sim() {
  [ -z "$SYM" ] && echo "$1" && return
  s="$1"
  for d in $SID; do s="${s//${d//$SYM/ }/$d}"; done
  echo "$s"
}

helper() {
  echo "Usage: $AG0 [[-H ipv4] -U user -P pass] -S <id1[/]> [-S <id2[/]>...] [-F formula] [-L logfile]"
  echo "       -H ipv4     Remote host IPv4 address"
  echo "       -U user     Remote session username"
  echo "       -P pass     Remote session password"
  echo "       -S id[/]    Sensor ID to read, slash for average calculation"
  echo "       -F formula  User defined formula calculation"
  echo "       -L logfile  Output to logfile as well"
  echo "*1 -H -U and -P are not required under systems with IPMI devices."
  echo "*2 -H can be omitted under BMC and 127.0.0.1 is assigned to ipv4."
  echo "*3 Quotes required for parameters with space characters."
  echo ""
}

log() {
  [ -z "$lgf" ] && return
  echo -e "$1" 2>/dev/null >>"$lgf"
  [ $? -ne 0 ] && echo -e "$ERR Unable to log to '$lgf', stop logging!!!" && lgf=""
}

out() {
  echo -e "$1"
  log "$1"
}

err() {
  [ -z "$1" ] && return
  e="${1/Error:/}"
  e="${e//\"/\'}"
  e="${e//!/}"
  out "Error: $(trim "$e")!!!\n"
  return 0
}

# Strings

spc() {
  [ $1 -ne 0 ] && eval "$AWK 'BEGIN { printf(\"%$1s\",\"\") }'"
}

isnum() {
  [ -z "$([ "$1" -eq "$1" ] 2>&1 && echo)" ] && echo 1 || echo 0
}

last() {
  n=1
  [ -n "$2" ] && n="$2"
  case "${n:0:1}" in
    -) echo "${1:0:$((${#1}+n))}";;
    *) echo "${1:$((${#1}-n))}";;
  esac
}

cut() {
  sp=" "; unset p1 p2
  if [ -n "$3" ]; then
    if [ $(isnum "$3") -eq 1 ]; then
      p1="NR==$3"
      p2="exit"
      [ -n "$4" ] && sp="$4"
    else
      sp="$3"
    fi
  fi
  eval "echo '$1' | $AWK -F'$sp' '$p1 { print \$$2; $p2 }'"
}

trim() {
  [ -z "$AWK" ] && echo "$1" && return
  s="$(echo "$1" | $AWK '{ sub(/^[[:space:]]+/,""); print }')"
  echo "$s" | $AWK '{ sub(/[[:space:]]+$/,""); print }'
}

count() {
  [ -n "$3" ] && op="IGNORECASE=1" || op=""
  eval "echo '$1' | $AWK 'BEGIN { c=0; $op } /$2/ { c++ } END { print c }'"
}

find() {
  [ -n "$3" ] && op="IGNORECASE=1" || op=""
  eval "echo '$1' | $AWK 'BEGIN { $op } /$2/ { print; exit }'" 2>&1
}

# Mathematics

math() {
  p=3
  [ -n "$2" ] && p="$2"
  eval "$AWK --lint 'BEGIN{ printf(\"%.${p}f\",$1); exit }'" 2>&1
}

max() {
  [ $1 -gt $2 ] && echo $1 || echo $2
}

# Misc

ipmierr() { #for sensor list|reading only
  e="$(find "$1" "^[^|]+$")"
  [ -n "$e" ] && err "$e" && return 1
}

cmdck() { #source, ipmitool and awk tested
  ./$1 >/dev/null 2>&1
  [ $? -eq 1 ] && echo "./$1" && return
  $1 >/dev/null 2>&1
  [ $? -eq 1 ] && echo "$1" && return
}


### BANNER

BNR="$BAN $VER"
out "$BNR"


### PARAMETERS (do early so all can dump to log if assigned)

[ $# -eq 0 ] && helper && eval "$HPX"

unset ip usr pss idx idz fun lgf
i=1; while [ $# -gt 1 ]; do
  case "$1" in
    -h|-H)
      ip="$2";;
    -u|-U)
      usr="$2";;      
    -p|-P)
      pss="$2";;
    -s|-S)
      idx="$idx|$2"; idz="$idz $i"; i=$((i+1));;
    -f|-F)
      fun="$2";;
    -l|-L)
      lgf="$2";;
    *)
      helper; eval "$HPX";;
  esac
  shift
  shift
done

[ $# -ne 0 ] && helper && eval "$HPX"
idx="${idx:1}"
idz="${idz:1}"
db "idx=$idx"
db "idz=$idz"
log "$BNR"


### USED COMMANDS

c="$(cmdck "awk")"
if [ -z "$c" ]; then
  c="$(cmdck "gawk")"
  [ -z "$c" ] && err "Awk/Gawk not found" && eval "$ERX"
fi
AWK="$c"

c="$(cmdck "ipmitool")"
[ -z "$c" ] && err "Ipmitool not found" && eval "$ERX"
IPMITOOL="$c"


### RE-ENTRY

p="$(ps -a)"
[ $(count "$p" " ${0##*/}$") -gt 1 ] && err "Running instance detected" && eval "$ERX"


### VALIDATIONS

# Id List

[ -z "$idx" ] && err "Sensors list missing" && eval "$ERX"

# Username and Password

[ -z "$usr" ] && x=0 || x=1
[ -n "$pss" ] && x=$((x+1))
[ $x -eq 1 ] || [ -n "$ip" -a $x -ne 2 ] && err "Username or password missing" && eval "$ERX"

# Ipv4

[ -z "$ip" -a $x -eq 2 ] && ip="127.0.0.1" #loop ip 4 bmc

unset auth
if [ -n "$ip" ]; then 
  c=0
  n="${ip//./ }"
  for i in $n; do
    if [ $i -lt 0 -o $i -gt 255 ]; then break; fi
    c=$((c+1))
  done
  [ $c -ne 4 ] && err "Invalid ip address '$ip'" && eval "$ERX"
  auth=" -H $ip -U $usr -P $pss"
fi
IPMITOOL="$IPMITOOL$auth"


### PROCESS

# Formula

unset sf
if [ -n "$fun" ] && [ "$(last "$fun")" = "/" ]; then
  sf=0
  fun="$(last "$fun" -1)"
fi
db "sf=$sf"

# Id List

unset ds ss ws #id sum width
for i in $idz; do
  d="$(cut "$idx" $i '|')"
  unset s
  if [ "$(last "$d")" = "/" ]; then
    d="$(last "$d" -1)"
    s=0
  fi
  ss="$ss|$s"
  ds="$ds|$d"
  dx="$dx \"$d\""
  ws="$ws ${#d}"
done
ss="${ss:1}"
ds="${ds:1}"
dx="${dx:1}"
ws="${ws:1}"
dx="$(sim "$dx")"
db "ss=$ss"
db "ds=$ds"
db "dx=$dx"
db "ws=$ws"

# Unit List

unset us wd
out "Initializing... \c"
s="$($IPMITOOL sensor list 2>&1)"
[ -n "$(ipmierr "$s")" ] && eval "$ERX"

for i in $idz; do
  d="$(cut "$ds" $i '|')"
  d="$(sim "$d")"
  u="$(find "$s" "^[[:space:]]*$d[[:space:]|]+")"
  db "for1d u=$u"
  [ -z "$u" ] && err "Sensor '$d' not found" && eval "$ERX"
  u="$(cut "$u" 3 '|')" #unit
  u="$(trim "$u")"
  db "for2d u=$u"
  [ -z "$u" ] || [ -n "$(find "$u" "discrete" i)" ] && err "Sensor '$d' not readable" && eval "$ERX"
  us="$us|$u"
  w=$(cut "$ws" $i)
  wd="$wd $(max ${#u} $w)"
done
us="${us:1}"
ws="${wd:1}"
out "Completed"
db "us=$us"
db "ws=$ws"

# Main Loop

cnt=1
while true; do

  # title
  tt=$(( cnt==1 || cnt%$LIN==0 ))

  # readings
  s="$(eval "$IPMITOOL sensor reading $dx 2>&1")"
  [ -n "$(ipmierr "$s")" ] && eval "$ERX"

  # values
  vs="$(cut "$s" 2 '|')"
  vs="$(trim "$vs")"
  db "vs=$vs"
  
  # format: values[/averages]
  i=1; unset sm os wd
  for v in $vs; do

    db "for1v i=$i"
    a=1 #align

    s="$(cut "$ss" $i '|')" #sum
    db "for1v s=$s"

    if [ -n "$s" ]; then
      s=$(math "$s+$v")
      av=$(math "$s/$cnt" 4)
      v="$v/$av"
      a=$((a+1))
      db "for2v v=$v"
    fi
    sm="$sm|$s"

    if [ $tt -eq 1 ]; then
      w="$(cut "$ws" $i)"
      wd="$wd $(max $((${#v}+a)) $w)"
      db "for3v wd=$wd"
    fi

    os="$os $v"
    i=$((i+1))
  done
  ss="${sm:1}"
  os="${os:1}"
  [ $tt -eq 1 ] && ws="${wd:1}"
  db "ss=$ss"
  db "os=$os"
  db "ws=$ws"
  
  # calculate/format: formula
  if [ -n "$fun" ]; then
    i=1; of="$fun"
    for v in $vs; do
      d="$(cut "$ds" $i '|')"
      of="${of//$d/$v}"
      i=$((i+1))
    done
    db "of=$of"
    of=$(math "$of" 12)
    db "of=$of"
    [ -n "$(find "$of" "awk" i)" ] && err "Invalid formula '$fun'" && eval "$ERX"
    [ -n "$sf" ] && sf=$(math "$sf+$of" 12)
    db "sf=$sf"
    of=$(math "$of" 3)
    [ -n "$sf" ] && av=$(math "$sf/$cnt" 4) && of="$of/$av"
  fi

  # output: prevent date/time insync from midnight carry
  dt="$(date +'%F %T')"
  ov="($cnt) $(cut "$dt" 2)" #value

  # output: id and unit (per 10 reports)
  if [ $tt -eq 1 ]; then

    w=${#ov} #ov always wider than od
    od="$(cut "$dt" 1)"
    od="$od$(spc $((w-${#od})))"
    ou="$(spc $w)"
 
    i=1
    for w in $ws; do
      d="$(cut "$ds" $i '|')"
      u="$(cut "$us" $i '|')"
      od="$od$SPC$d$(spc $((w-${#d})))"
      ou="$ou$SPC$u$(spc $((w-${#u})))"
      i=$((i+1))
    done
    
    [ -n "$fun" ] && od="$od$SPC$fun"
    out "\n$od"
    out "$ou"
  fi

  i=1
  for w in $ws; do
    o=$(cut "$os" $i)
    ov="$ov$SPC$o$(spc $((w-${#o})))"
    i=$((i+1))
  done
  [ -n "$fun" ] && ov="$ov$SPC$of"
  out "$ov"

  cnt=$((cnt+1))
  sleep 0.1
done
