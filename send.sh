#!/usr/bin/env bash
srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $srcDir/ha.sh

echo_log "Executing send.sh"

if [ $# -le 0 ]; then
    printf "Use: send <device> <command>\n"
    printf "     known devices:\n"
    for dev in "${devices[@]}"
    do
	printf "         $dev\n" 
    done
    exit 0;
fi
    
deviceName=$1;

if [ $# -le 1 ]; then
    printf "Use: send <device> <command>\n"
    printf "     Device $deviceName is >>$deviceType<< device\n"
    exit 0;
fi

shift
command="$@";
send $deviceName "$command"
