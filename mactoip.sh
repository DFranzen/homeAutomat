#!/usr/bin/env bash
srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $srcDir/ha.sh
#log="yes"

if [ "$#" -le 0 ]; then
    cmd="help";
else
    cmd="$(echo $1|xargs)";
fi

if [ "$cmd" == "lookup" ]; then
    if [ "$#" -ge 2 ]; then
	mac=$2
	if [[ $log ]]; then echo_log "MacToIP: looking up mac $mac"; fi
	ip=$(/usr/sbin/arp -an | grep -i "$mac" | awk '{print $2}' | sed 's/[()]//g' | head -n 1)
	if [[ $ip ]]; then
	    echo_log "MacToIP: found IP: $ip"
	    echo $ip;
	    exit 0
	else
	    echo_log "MacToIP: no IP found for $mac"
	    echo "0.0.0.0";
	    exit 1
	fi
    else
	echo_log "MacToIP: no mac provided"
	echo "0.0.0.0";
	exit 1;
    fi
else
    echo_log "MacToIP: Updating table"
    ip=$(getbc_ip|grep -oP "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.")
    nmap -sP ${ip}0/24 >/dev/null
fi


if [ "$cmd" == "help" ]; then
    echo "$(date +"%T") mactoip help executed" >> $srcDir/log.txt
    printf "Usage: mactoip <cmd> <param>"
    printf "possible cmd: \n"
    printf " help\t\t displays this information\n"
    printf " update\t\t updates the data about the network\n"
    printf " lookup <mac>\t\t return the ip for the given <mac>\n"
fi
