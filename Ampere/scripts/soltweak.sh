#!/bin/bash
# Ampere IPMI SOL Tweak (default Mt.Snow)
# 2021/01/19 use at your own risk, bugs to clark.chang@amperecomputing.com

COOKIE=/tmp/".${0##*/}"

if [ ! -e "$COOKIE" ]; then
	echo 1 > "$COOKIE"
	HOST=127.0.0.1
	USER=admin
	PASS=password
	[ -n "$1" ] && HOST="$1"
	[ -n "$2" ] && USER="$2"
	[ -n "$3" ] && PASS="$3"
	IPMISOLSET="ipmitool -H $HOST -U $USER -P $PASS -I lanplus sol set"
	$IPMISOLSET character-accumulate-level 10
	$IPMISOLSET character-send-threshold 32
	$IPMISOLSET retry-interval 10
fi
