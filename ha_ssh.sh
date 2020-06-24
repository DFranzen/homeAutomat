#!/usr/bin/env bash
export included_ssh="true"

srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo_log "ssh plugin: Loading"

ssh_cleanup() {
    local deviceName=$1
    # remove files for the broken connection
    rm $srcDir/sshSockets/sshSocket.$deviceName 2> /dev/null
    rm $srcDir/sshSockets/sshResult.$deviceName 2> /dev/null
    
    # remove all processes, that are still watching for the deleted files
    lsof -i TCP:22|grep "$srcDir/sshSockets/sshSocket.$deviceName" | grep "(deleted)" | awk -F ' ' '{print $2}'|while read pid; do kill $pid; done
    lsof -i TCP:22|grep "$srcDir/sshSockets/sshResult.$deviceName" | grep "(deleted)" | awk -F ' ' '{print $2}'|while read pid; do kill $pid; done
}

ssh_is_available() {
    local deviceName=$1;
    
    #test if socket file exists
    echo_log "ssh_is_available: Checking for Socket file $srcDir/sshSockets/sshSocket.$deviceName"
    if [ -f "$srcDir/sshSockets/sshSocket.$deviceName" ]; then

	echo_log "ssh_is_available: Socket file found -> testing if functional"
	
        #test if functional
        result=$(ssh_get $deviceName "echo connected")
        if [ -z "$result" ]; then
            # not functional -> cleanup
            ssh_cleanup $deviceName
        else
            echo "YES"
            return 0
        fi
    fi

    echo_log "ssh_is_available: No Socket available -> device not available"
    echo "NO"
    return 1
}

ssh_is_playing() {

    deviceName=$1

    echo_log "ssh_is_playing: Checking if playing process on $deviceName"
    soundPid=$(ssh_playing_Pid $i_device)
    if [ -z "$soundPid" ]; then
        echo_log "get_current: No sound playing process -> is not playing";
	echo "NO"
        continue
    fi
    echo "YES"
}

ssh_playing_Pid () {
    deviceName=$1
    ssh_get $deviceName "pacmd list-sink-inputs|grep application.process.id|grep -oP [0-9]*"
    return 0;
}

ssh_connect() {
    deviceName=$1

    ssh_cleanup $deviceName

    deviceUser=${deviceList["$deviceName|user"]}
    deviceIp=$(get_ip "$deviceName")
    
    if [ deviceIp == "0.0.0.0" ]; then
        ssh_cleanup $deviceName
        echo_log "ssh_connect: ERROR Cannot connect to $deviceName, no IP found"
        return
    fi

    echo_log "ssh_connect: connecting on ip $ip"
    # create empty Socket and result file
    cmd_connect_ssh="echo \"\" > $srcDir/sshSockets/sshSocket.$deviceName"
    sudo -u $ha_user bash -c "$cmd_connect_ssh"
    cmd_connect_ssh="echo \"\" > $srcDir/sshSockets/sshResult.$deviceName"
    sudo -u $ha_user bash -c "$cmd_connect_ssh"

    echo_log "ssh_connect: Connecting to socket"
    
    #create Socket
    /usr/bin/tail -f $srcDir/sshSockets/sshSocket.$deviceName | ssh $deviceUser@$deviceIp > $srcDir/sshSockets/sshResult.$deviceName 2> /dev/null &
    pid="$!"
    echo_log "ssh_connect: connection established with pid $pid"
    echo "echo PID: $pid" >> $srcDir/sshSockets/sshSocket.$deviceName
}


ssh_check_and_connect() {
    deviceName=$1;
    echo_log "ssh_check_and_connect: Checking for connection to $deviceName"

    ip=$(get_ip $deviceName)
    if [ "$ip" == "0.0.0.0" ]; then
	echo_log "ssh_check_and_connect: $deviceName is off"
        return
    fi
    
    result=$(ssh_is_available $deviceName)
    if [ "$result" == "YES" ]; then
	    echo_log "ssh_check_and_connect: $deviceName still connected"
    else
	    echo_log "ssh_check_and_connect: Establishing new connection to $deviceName"
	    ssh_connect $deviceName
    fi
}

ssh_lookup_cmd() {
    deviceName=$1
    shift
    cmd="$@"
    if [ "$cmd" == "__ON__" ]; then
        wol=${deviceList["$deviceName|wol"]}
        if [ "x$wol" == "x" ]; then
            echo_log "ssh_lookup_cmd: ERROR __ON__ requested but no way to turn on"
            cmd=""
        else
            #__ON__ is handled in send via WoL
            cmd="__ON__"
        fi
    elif [ "$cmd" == "__OFF__" ]; then
	    cmd="xdotool key --clearmodifiers 150"
    elif [ "$cmd" == "__PLAY__" ]; then
	    cmd="xdotool key --clearmodifiers space"
    elif [ "$cmd" == "__PAUSE__" ]; then
	    cmd="xdotool key --clearmodifiers space"
    elif [ "$cmd" == "__NETFLIX__" ]; then
	    echo_log "ssh_lookup_cmd: sending netflix command"
	    cmd="netflix"
    elif [ "$cmd" == "__FULLSCREEN__" ]; then
	    cmd="xdotool key --clearmodifiers f"
    fi

    echo "$cmd"
    return 0;
}

# This function is the interface for ha.sh
ssh_send() {
    ssh_send_to $@
    #save this Socket for quick CURRENT
    ln -s -f $srcDir/sshSockets/sshSocket.$deviceName $srcDir/sshSockets/sshSocket.__CURRENT__	
}

#This function just sends 
ssh_send_to() {
    # assumes the socket has been opened before (use from send.sh, where ssh_connect.sh has been executed before)
    deviceName=$1
    shift
    local cmd="$@"

    if [ "$cmd" == "__ON__" ]; then
        echo "WOL"
        local deviceMacs=${deviceList["$deviceName|macs"]}
        wolVerify "$deviceMacs" >> $srcDir/log.txt
    else 

	#Check for IP anyway
	deviceIp=$(get_ip "$deviceName")
    
	if [ deviceIp == "0.0.0.0" ]; then
	    echo_log "ssh_send_to: ERROR Cannot connect to $deviceName, no IP found"
	    return
	fi


	cmd=$(echo "export DISPLAY=:0;$cmd");

	echo_log "ssh_send_to: sending command $cmd via ssh to $deviceName as $(whoami)"
	echo "$cmd &" >> $srcDir/sshSockets/sshSocket.$deviceName 2> /dev/null
    fi
}

ssh_get() {
    deviceName="$1"
    shift
    cmd="$@"

    # prepare Result stream
    lno_pre=$(cat $srcDir/sshSockets/sshResult.$deviceName | wc -l)
    # send command
    # TODO: here we should add an echo "__SSH_GET_FINISHED__ and wait for this line to appear"
    ssh_send_to "$deviceName" "$cmd"
    
    # read Result
    echo_log "ssh_get: Command sent, waiting for response"
    lno_post=$(cat $srcDir/sshSockets/sshResult.$deviceName | wc -l)
    tries=300
    while [ "$lno_pre" -eq "$lno_post" ]; do
	lno_post=$(cat $srcDir/sshSockets/sshResult.$deviceName | wc -l)
	tries=$((tries-1))
	if [ "$tries" -le "0" ]; then
	    break;
	fi
    done

    result=$(tail -n $((lno_post-lno_pre)) $srcDir/sshSockets/sshResult.$deviceName)
    echo "$result"
}

ssh_update() {
    i_device=$1
    ssh_check_and_connect $i_device
}


export -f ssh_connect
export -f ssh_check_and_connect
export -f ssh_get

export -f ssh_update
export -f ssh_is_available
export -f ssh_is_playing
export -f ssh_lookup_cmd
export -f ssh_send




     
