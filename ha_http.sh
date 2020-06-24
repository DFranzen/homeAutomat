http_is_available() {
    local ip=$(get_ip "$deviceName")
    if [ "$ip" == "0.0.0.0" ]; then
        echo "NO"
        return
    fi

    echo "YES"
}

http_is_playing() {
    echo "YES"
}

http_lookup_cmd() {
    local deviceName=$1
    local cmd=$2

    if [ "$cmd" == "__ON__" ]; then
        cmd="On"
    elif [ "$cmd" == "__OFF__" ]; then
        cmd="off"
    fi
    echo "$cmd"
}

http_send() {
    local deviceName=$1
    shift
    local cmd="$@"

    local ip=$(get_ip "$deviceName")

    if [ "$ip" == "0.0.0.0" ]; then
        echo_log "http_send: corresponding IP not found"
        return 1
    fi

    echo_log "http_send: Device found at $ip"
    local cmd_exec=${deviceList["$deviceName|cmd"]}
    if [ "x$cmd_exec" == "x" ]; then
        cmd_exec="$cmd"
    fi
    cmd_exec=${cmd_exec//__IP__/$ip}
    cmd_exec=${cmd_exec//__CMD__/$cmd}
    echo_log "http_send: Requesting http: $ip$cmd_exec "
    curl $ip$deviceURL$cmd_exec
}

export -f http_is_available
export -f http_lookup_cmd
export -f http_send
export -f http_is_playing
