#!/bin/bash

# SP-4L Command Line Tool -> [init] -> login -> state, power## or URL... -> logout
# clark.chang@amperecomputing.com Oct 2020

VERS="0.1 (initial)"
DATE="2020/10/16"
HELP="usage: ${0##*/} command -h host [-u username] [-p password]\nwhere command could be init | login | state | power## | URL | logout"
INFO="version $VERS $DATE bugs to clark.chang@amperecomputing.com"
RISK="have fun at your own risk"

EXIT="return $RET >&/dev/null; exit $RET"
EXOK="RET=0; $EXIT"
EXER="RET=1; $EXIT"

bad()    { echo "Error: $1!"; }
badcmd() { echo "Bad command '$1'!"; }

[ $# -eq 0 ] && echo -e "$HELP\n$INFO\n$RISK" && eval "$EXER"

HOST=
CMMD=
USER=admin
PASS=admin

LOGAUTH=login_auth.csp
PWRCTRL=power_monitor_frame.csp
COOKSET=Set-Cookie:
COOKFIL=/tmp/SP4L-Cookie
STATFIL=/tmp/SP4L-States

STATES=
COOKIE=

while [ $# -ne 0 ]; do
    case "$1" in
        -H|-h) HOST="$2"; shift;;
        -U|-u) USER="$2"; shift;;
        -P|-p) PASS="$2"; shift;;
        -*)    bad "Option '$1'"; eval "$EXER";;
         *)    [ -n "$CMMD" ] && { bad "Multiple commands"; eval "$EXER"; }
	       CMMD="$1";;
    esac
    shift
done

[ -z "$CMMD" ] && bad "No command" && eval "$EXER"
[ $CMMD = init ] && HOST=0.0.0.0 # dummy

[ -z "$HOST" ] && [ -n "$SP4L_HOST" ] && HOST="$SP4L_HOST"
[ -z "$HOST" ] && bad "No host" && eval "$EXER"
[[ ! "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && bad "Host '$HOST'" && eval "$EXER"

[ -e "$COOKFIL" ] && COOKIE=`cat "$COOKFIL"`
[ -e "$STATFIL" ] && STATES=(`cat "$STATFIL"`)

#
# $1=URL, $2=keystring
#
GET() {
    [ -z "$COOKIE" ] && return 1
    curl -s -H "$COOKIE" "$HOST/$1" 2>&1 | grep "$2"
    return $?
}

#
# $1=URL, $2=data, $3=keystring
#
POST() {
    curl -s -i -d "$2" "$HOST/$1" 2>&1 | grep "$3"
    return $?
}

init() {
    rm -f "$COOKFIL" "$STATFIL" >&/dev/null
}

logout() {
    [ -z "$COOKIE" ] && return 0
    GET logout.csp "$LOGAUTH" >&/dev/null
    [ $? -ne 0 ] && return 1
    init
    return $?
}

login() {
    logout
    [ $? -ne 0 ] && return 1
    COOKIE=`POST "$LOGAUTH" "auth_user=$USER&auth_passwd=$PASS" "$COOKSET"`
    [ $? -ne 0 ] && return 1
    COOKIE="${COOKIE%%[^:digit:]}"
    COOKIE="${COOKIE/Set-/}"
    echo "$COOKIE" > "$COOKFIL"
    if [ $? -ne 0 ]; then logout; return 1; fi
    return 0
}

#
# Response Data Array ex. ['SP4L','NULL','NULL','1','1','31',['1','1'],['1','1','1','0'],['0.20','0.00','0.00','0.00']
#
# [0]=SP4L: SRM name or 'D' for debugging => index 0
# [1]=NULL: temperature, [2]=NULL: relative humidity => index 1 2
# [3]=1: SRM no => index 3
# [4]=1: SRM status => index 3
# [5]=31: SRM temperature => index 5
# [6]=1,1: source power state => index 6 7
# [7]=1,1,1,0: power state (ON, ON, ON, OFF) => index 8 9 10 11
# [9]=0.20,0.00,0.00,0.00: current in amp => index 12 13 14 15
#
state() {
    STATES=`GET "$PWRCTRL$1" "SP4L"`
    [ $? -ne 0 ] && return 1
    STATES=(${STATES//[,\'\[\]]/ })
    [ ${#STATES[@]} -ne 16 ] && return 1
    echo "${STATES[@]}" > "$STATFIL"
    return $?
}

#
# $1=0=all powers => all_status=$2 or $1=1-4=power_id => power_id=$1&status=$2
# $2=1:on 2:off 3:reset
#
PWRCNV=(2 1 3)
power() {
    [ -z "$STATES" ] && state
    local d a=${PWRCNV[$2]}
    [ $1 -eq 0 ] && d="all_status=$a" || d="power_id=$1&status=$a"
    state "?srmno=${STATES[3]}&$d"
    return $?
}

case "$CMMD" in
    init)
        init
        [ $? -ne 0 ] && { bad Init; eval "$EXER"; }
	;;
    login)
        login
        [ $? -ne 0 ] && { bad Login; eval "$EXER"; }
        state
	;;
    logout)
        logout
        [ $? -ne 0 ] && { bad Logout; eval "$EXER"; }
	;;
    power[0-9][0-9])
        t=${CMMD#power}
        i=${t:0:1}; [[ $i =~ [0-4] ]] || { badcmd "$CMMD"; eval "$EXER"; } # 0:all, 1-4:individual
        a=${t:1:1}; [[ $a =~ [0-2] ]] || { badcmd "$CMMD"; eval "$EXER"; } # 0:off, 1:on, 2:reset
        power $i $a
        [ $? -ne 0 ] && { bad Power; eval "$EXER"; }
	;;
    state)
        state
        [ $? -ne 0 ] && { bad State; eval "$EXER"; }
	echo "${STATES[@]:8:8}" # four power states and four consuming currents in amp
	;;
    *)
        echo "Unknown command '$CMMD' do GET instead!"
        GET "$CMMD"
        [ $? -ne 0 ] && { bad GET; eval "$EXER"; }
        echo
	;;
esac

eval "$EXOK"

