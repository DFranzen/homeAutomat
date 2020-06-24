srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $srcDir/ha_aux.sh
. $srcDir/ha_plugins.sh
load_config

# usage: send_to deviceName cmd

# Special deviceNames:
# __CURRENT__: the last used viable device

# Special cmds:
# __ON__: turn the device on
# __OFF__: turn the device off
# __PLAY__: start/continue the playback on the device
# __PAUSE__: pause/stop the playback on the device
# __NETFLIX__: start Netflix
# __FULLSCREEN__: maximizes Video

get_ip() {
    local deviceName=$1
    
    local ipList=${deviceList["$deviceName|ips"]}
    if [ "x$ipList" == "x" ]; then
		echo_log "get_ip: No IP set for $deviceName -> Trying Mac2Ip"

		local deviceMacs=${deviceList["$deviceName|macs"]}
		local ip=$(macList2Ip "$deviceMacs")

		echo "$ip"
		return
    else
		IFS='|' read -r -a ips <<< $ipList
		for index in "${!ips[@]}"
		do
			local ip=${ips[index]}

			if fping -c1 -t 200 $ip &> /dev/null; then
				echo $ip;
				echo_log "get_ip: found at $ip"
				return
			fi
		done
    fi
    echo "0.0.0.0"
}   

get_current() {
    local curr_ts=-1

    local deviceName="__CURRENT__"

    for i_device in "${devices[@]}"
    do
		echo_log "get_current: Testing $i_device as __CURRENT__"

		# test if this device has playback
		local playback=${deviceList["$i_device|playback"]}
		if [ -z "$playback" ]; then
			echo_log "get_current: device does not playback content -> not suitable"
			continue
		fi
		
		# test if more recent than current candidate
		local ts=$(stat --printf=%Y $srcDir/used/$i_device.used)
		if [ "$?" -gt 0 ] && [ "$curr_ts" -ne "-1" ]; then
			echo_log "get_current: $i_device has never been used -> Not suitable"
			continue;
		fi
		if [ "$curr_ts" -gt "$ts" ] && [ "$curr_ts" -ne "-1" ]; then
			echo_log "get_current: $i_device has not been used since $ts -> Not suitable"
			continue;
		fi 
		
		# test if device is available
		local avail=$(is_available $i_device)
		if [ "$avail" == "NO" ]; then
			echo_log "get_current: $i_device not available -> cannot be current"
			continue
  		fi

		# test if switched on
		#deviceType=${deviceList["$i_device|type"]}
		#if [  "$deviceType" == "ssh" ] && [ "$cmd" == "__PAUSE__" ]; then
		#	echo_log "get_current: Checking if playing process on $ip"
		#	soundPid=$(playingPid $ip $i_device)
		#	if [ -z "$soundPid" ]; then
		#		echo_log "get_current: No sound playing process -> cannot be current";
		#		continue
		#	fi 
		#fi 
			
		echo_log "get_current: viable candidate for __CURRENT__ device: $i_device, last used in $ts"	    
		curr_ts=$ts
		deviceName=$i_device
    done
    echo $deviceName
}

is_available() {
	local deviceName=$1;

	echo_log "is_available: Checkig if device $deviceName is available"

	local type=${deviceList["$deviceName|type"]}
	local del_fun="${type}_is_available"

	local avail=$(LC_ALL=C type -t $del_fun)
	if [ -z "$avail" ]; then
		echo_log "is_available: Type $type does not support check for available -> Assuming available"
		echo "YES"
		return
	fi
	
	echo_log "is_available: Delegating to $del_fun"
	local del_cmd="$del_fun $deviceName"
	echo_log "is_available: Executing $del_cmd"

	$del_cmd
}

lookup_cmd() {
    local deviceName=$1;
    shift
    local cmd="$@"

	echo_log "lookup_cmd: Looking up command $cmd for $deviceName"

	#Check if there is a command override:
    cmd_override=${deviceList["$deviceName|cmd|$cmd"]}
    if [ "x$cmd_override" != "x" ]; then
		echo_log "lookup_cmd: Override $cmd -> $cmd_override"
        echo "$cmd_override"
		return
	fi

	local type=${deviceList["$deviceName|type"]}
	local del_fun="${type}_lookup_cmd"

	local avail=$(LC_ALL=C type -t $del_fun)
	if [ -z "$avail" ]; then
		echo_log "lookup_cmd: Type $type does not support Command Loockup -> Assuming no translation needed"
		echo "$cmd"
		return
	fi
	
	echo_log "lookup_cmd: Delegating to $del_fun"
	local del_cmd="$del_fun $deviceName $cmd"
	echo_log "lookup_cmd: Executing $del_cmd"

	$del_cmd
}

is_playing() {
	local deviceName=$1;

	echo_log "is_playing: Checkig if device $deviceName is playing"

	local type=${deviceList["$deviceName|type"]}
	local del_fun="${type}_is_playing"

	local avail=$(LC_ALL=C type -t $del_fun)
	if [ -z "$avail" ]; then
		echo_log "is_playing: Type $type does not support check for playing -> Assuming playing"
		echo "YES"
		return
	fi
	
	echo_log "is_playing: Delegating to $del_fun"
	local del_cmd="$del_fun $deviceName"
	echo_log "is_playing: Executing $del_cmd"

	$del_cmd
}

send() {
    local deviceName=$1;
    shift
    local cmd="$@"
    echo_log "------------------- Command is $cmd ------------------------"

        if [ "$deviceName" == "__CURRENT__" ]; then
		deviceName=$(get_current)
		if [ "$deviceName" == "__CURRENT__" ]; then
			echo_log "send: No suitable current device found"
			exit 1
		fi
	fi 

	echo_log "send: sending to $deviceName"
	local type=${deviceList["$deviceName|type"]}
	local del_fun="${type}_send"
	local avail=$(LC_ALL=C type -t ${del_fun})
	if [ -z "$avail" ]; then
		echo_log "send: Type ${type} is unknown -> aborting send"
		return
	fi

	echo_log "send: resetting used date: $deviceName.used"
	touch "$srcDir/used/$deviceName.used"

	cmd=$(lookup_cmd $deviceName $cmd)
	echo_log "send: Translated Command is $cmd";

	if [ "x$cmd" == "x" ]; then
		echo_log "send: No command recieved -> Abort"
		return
	fi


	local del_cmd="$del_fun $deviceName $cmd"
	$del_cmd
	return

	#elif [ "$deviceType" == "sshLirc" ]; then
	#	echo_log "send: connecting to $deviceName via ssh as $(whoami)"
	#	deviceUser=${deviceList["$deviceName|user"]}
	#	passwd=${deviceList["$deviceName|password"]}
	#	user=${deviceList["$deviceName|user"]}
	#	lircName=${deviceList["$deviceName|lircName"]}

	#	ip=$(get_ip "$deviceName")
	#	if [ "$ip" == "0.0.0.0" ]; then
	#		echo_log "send: no current ip for $deviceName found, trying network rediscovery"
	#		$srcDir/mactoip.sh update
	#		return 1
	#	fi 
		
	#	send_ssh $deviceName "irsend SEND_ONCE $lircName $cmd"
}

# This method is triggered every minute for maintenance of connections
update() {
	local deviceName=$1;

	echo_log "update: maintaining $deviceName"

	local type=${deviceList["$deviceName|type"]}
	local del_fun="${type}_update"

	local avail=$(LC_ALL=C type -t $del_fun)
	if [ -z "$avail" ]; then
		echo_log "update: Type $type does not support update"
		return
	fi
	
	echo_log "update: Delegating to $del_fun ($avail)"
	local del_cmd="$del_fun $deviceName"
	echo_log "update: Executing $del_cmd"

	$del_cmd
}

update_all() {
    echo_log "--------------- Updating all connections ---------------"

    for i_device in "${devices[@]}"
    do
		update $i_device
    done
}


get() {
    deviceName="$1"
    shift
    cmd="$@"

    echo_log "Get from $deviceName"
    deviceType=${deviceList["$i_device|type"]}

    if [ "$deviceType" == "ssh" ] || [ "$deviceType" == "sshLirc" ]; then
		value=$(ssh_get $deviceName $cmd)
    fi
    echo $value
}
       
export -f send
export -f update
export -f update_all
export -f get
export -f get_current
