#!/bin/bash
# Ampere Mt.Snow UART Tweak
# 2021/01/19 use at your own risk, bugs to clark.chang@amperecomputing.com
# usage: ${0##*/} n
# n: 0= back to original settings, 2= enable ttyS2 for SCP, 4= enable ttyS4 for ATF


COOKIE="/tmp/.${0##*/}"
OUTPUT=">&/dev/null"

# /etc/init.d/ipmistack restart
ipmistack() {
	killall -1 IPMIMain
	eval /usr/local/bin/IPMIMain --daemonize --reg-with-procmgr $OUTPUT
}

# /etc/init.d/sync-agent restart
sync_agnet() {
	SERVER_PATH="/usr/local/sync-agent/"
	AGENT_NAME="agent.lua"
	RF2GROUP_AGENT_NAME="subagents/redfish-2-redfishgroup.lua"
	GROUP2FN_AGENT_NAME="subagents/redfishgroup-2-fns.lua"
	INIT_AGENT_NAME="subagents/init-agent.lua"
	TELEMETRY_AGENT_NAME="subagents/telemetry.lua"
	SYNC_AGENT_PID_DIR="/var/run/sync-agent-subagents/"
	SYNC_AGENT_PID="/var/run/sync-agent.pid"
	RF2GROUP_AGENT_PID="/var/run/redfish2redfishgroup.pid"
	GROUP2FN_AGENT_PID="/var/run/redfishgroup2fns.pid"
	TELEMETRY_AGENT_PID="/var/run/telemetry.pid"
	TEMP_RDB="/tmp/temp-*.rdb"
	TEMP_RSYNC="/conf/.redis-dump.rdb.*"

	kill -9 `cat $SYNC_AGENT_PID`
	rm $SYNC_AGENT_PID
	kill -9 `cat $RF2GROUP_AGENT_PID`
	rm $RF2GROUP_AGENT_PID
	kill -9 `cat $GROUP2FN_AGENT_PID`
	rm $GROUP2FN_AGENT_PID
	kill -9 `cat $TELEMETRY_AGENT_PID`
	rm $TELEMETRY_AGENT_PID
	if [ $SYNC_AGENT_PID_DIR* != "$SYNC_AGENT_PID_DIR*" ]; then
		for SUBAGENT in $SYNC_AGENT_PID_DIR*
		do
			kill -9 `cat $SUBAGENT`
			rm $SUBAGENT
		done
	fi
	sleep 3
	export LD_LIBRARY_PATH=/usr/local/lib
	ls $TEMP_RDB 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ];then rm $TEMP_RDB;fi;
		ls $TEMP_RSYNC 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ];then rm $TEMP_RSYNC;fi;
	echo 4 > /tmp/redfish-start
	cd $SERVER_PATH; luajit $INIT_AGENT_NAME
	eval luajit $AGENT_NAME $OUTPUT
	eval luajit $RF2GROUP_AGENT_NAME $OUTPUT
	eval luajit $GROUP2FN_AGENT_NAME $OUTPUT
	eval luajit $TELEMETRY_AGENT_NAME $OUTPUT
}

case "$1" in
	0)
		rm -f "$COOKIE.2" >&/dev/null
		if [ -e "$COOKIE.4" ]; then
			rm -f "$COOKIE.2" >&/dev/null
			gpiotool --set-data-low  43 # select CPU ATF to HEADER
			gpiotool --set-data-high 61
			OUTPUT=
			ipmistack
			sync_agnet
		fi
		;;
    2)
		if [ ! -e "$COOKIE.2" ]; then
			echo 1 > "$COOKIE.2"
			devmem 0x1E6E2000 32 0x1688A8A8 # SCU unlock
			devmem 0x1E6E2080 32 0xC0C00000 # enable UART3 Tx/Rx
			devmem 0x1E6E2000 32 0x00000000 # SCU lock
			gpiotool --set-data-high 60 # select CPU SCP to BMC UART3 (/dev/ttyS2)
			gpiotool --set-data-low  59
		fi
		;;

    4)
		if [ ! -e "$COOKIE.4" ]; then
			echo 1 > "$COOKIE.4"
			ipmistack
			sync_agnet
			gpiotool --set-data-high 43 # select CPU ATF to BMC UART5 (/dev/ttyS4)
			gpiotool --set-data-low  61
		fi
		;;
esac
