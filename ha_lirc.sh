lirc_lookup_cmd() {
    local deviceName=$1
    local cmd=$2

    local ip=$(get_ip "$deviceName")
    if [ "$cmd" == "__ON__" ]; then
        if [ "$ip" == "0.0.0.0" ] || [ "$ip" == "" ]; then
            local wol=${deviceList["$deviceName|wol"]}
            if [ "$wol" == "" ]; then
                cmd="KEY_POWER"
            else
                cmd="__ON__"
            fi 
        else
            echo_log "lirc_lookup_cmd: $deviceName already turned on -> abort"
            cmd=""
        fi
    elif [ "$cmd" == "__OFF__" ]; then
        local ips=${deviceList["$deviceName|ips"]}
        local macs=${deviceList["$deviceName|mas"]}

        if [ "x$ips" != "x" ] || [ "x$macs" != "x"]; then
            if [ "$ip" == "0.0.0.0" ]; then
                echo_log "Already turned off"
                cmd=""
            else
                cmd="KEY_POWER"
            fi
        else
            # Don't know whether it is off -> assume need to turn off
            cmd="KEY_POWER"    
        fi
    fi

    echo "$cmd"
}

lirc_send() {
    local deviceName=$1
    local cmd=$2

    if [ "$cmd" == "__ON__" ]; then
        deviceMacs=${deviceList["$deviceName|macs"]}
        wolVerify "$deviceMacs"
        return 0
    fi

    
    local rep=${deviceList["$deviceName|$cmd|repeat"]}
    if [ "$rep" == "" ]; then
        rep=1
    fi
    
    for (( i=1; i<=$rep; i++ )); do
        echo_log "Sending $cmd to $deviceName"
        irsend SEND_ONCE $deviceName $cmd
    done
}

export -f lirc_lookup_cmd
export -f lirc_send