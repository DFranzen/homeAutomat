python_is_available() {
    echo "YES"
}

python_is_playing() {
    echo "YES"
}

python_lookup_cmd() {
    deviceName=$1
    cmd=$2

    if [ "$cmd" == "__ON__" ]; then
        cmd="on"
    elif [ "$cmd" == "__OFF__" ]; then    
        cmd="off"
    fi      
    echo "$cmd"
}

python_send() {
    local deviceName=$1
    shift
    local cmd="$@"

    local ip=$(get_ip "$deviceName")
    if [ "$ip" == "0.0.0.0" ]; then
        echo_log "send_python: no ip found for $deviceName"
        return 1
    fi

    local cmd_exec=${deviceList["$deviceName|cmd"]}
    cmd_exec=${cmd_exec//__IP__/$ip}
    cmd_exec=${cmd_exec//__CMD__/$cmd}
    echo_log "send_python: executing $cmd_exec"
    python $srcDir/$cmd_exec
}

export -f python_is_available
export -f python_lookup_cmd
export -f python_send
export -f python_is_playing
