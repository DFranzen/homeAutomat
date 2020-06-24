#setup:
#- install apache2 ??
#- install php-cli ??
#- install php-cgi
#- install php-curl

# Known commands:
#"NRC_CH_DOWN-ONOFF", // channel down
#"NRC_CH_UP-ONOFF", // channel up
#"NRC_VOLUP-ONOFF", // volume up
#"NRC_VOLDOWN-ONOFF", // volume down
#"NRC_MUTE-ONOFF", // mute
#"NRC_TV-ONOFF", // TV
#"NRC_CHG_INPUT-ONOFF", // AV,
#"NRC_RED-ONOFF", // red
#"NRC_GREEN-ONOFF", // green
#"NRC_YELLOW-ONOFF", // yellow
#"NRC_BLUE-ONOFF", // blue
#"NRC_VTOOLS-ONOFF", // VIERA tools
#"NRC_CANCEL-ONOFF", // Cancel / Exit
#"NRC_SUBMENU-ONOFF", // Option
#"NRC_RETURN-ONOFF", // Return
#"NRC_ENTER-ONOFF", // Control Center click / enter
#"NRC_RIGHT-ONOFF", // Control RIGHT
#"NRC_LEFT-ONOFF", // Control LEFT
#"NRC_UP-ONOFF", // Control UP
#"NRC_DOWN-ONOFF", // Control DOWN
#"NRC_3D-ONOFF", // 3D button
#"NRC_SD_CARD-ONOFF", // SD-card
#"NRC_DISP_MODE-ONOFF", // Display mode / Aspect ratio
#"NRC_MENU-ONOFF", // Menu
#"NRC_INTERNET-ONOFF", // VIERA connect
#"NRC_VIERA_LINK-ONOFF", // VIERA link
#"NRC_EPG-ONOFF", // Guide / EPG
#"NRC_TEXT-ONOFF", // Text / TTV
#"NRC_STTL-ONOFF", // STTL / Subtitles
#"NRC_INFO-ONOFF", // info
#"NRC_INDEX-ONOFF", // TTV index
#"NRC_HOLD-ONOFF", // TTV hold / image freeze
#"NRC_R_TUNE-ONOFF", // Last view
#"NRC_POWER-ONOFF", // Power off

#"NRC_REW-ONOFF", // rewind
#"NRC_PLAY-ONOFF", // play
#"NRC_FF-ONOFF", // fast forward
#"NRC_SKIP_PREV-ONOFF", // skip previous
#"NRC_PAUSE-ONOFF", // pause
#"NRC_SKIP_NEXT-ONOFF", // skip next
#"NRC_STOP-ONOFF", // stop
#"NRC_REC-ONOFF", // record

#// numeric buttons
#"NRC_D1-ONOFF", "NRC_D2-ONOFF", "NRC_D3-ONOFF", "NRC_D4-ONOFF", "NRC_D5-ONOFF",
#"NRC_D6-ONOFF", "NRC_D7-ONOFF", "NRC_D8-ONOFF", "NRC_D9-ONOFF", "NRC_D0-ONOFF",

viera_is_available() {
    local ip=$(get_ip "$deviceName")

    local res=$(php-cgi -f $srcDir/TVinfo.php ip=$ip|grep "CurrentVolume")
    if [ -z "$res" ]; then
        echo "NO";
        return 1
    fi
      
    echo "YES";
    return 0
}

viera_is_playing() {
    echo "YES"
}

viera_lookup_cmd() {
    local deviceName=$1
    local cmd=$2

    if [ "$cmd" == "__ON__" ]; then
        #on is handeled via WOL
        local wol=${deviceList["$deviceName|wol"]}
        if [ "$wol" == "" ]; then
            echo_log "viera_lookup_cmd: __ON__ requested but no way to turn on"
            cmd=""
        else 
            cmd="__ON__"            
        fi
    elif [ "$cmd" == "__FULLSCREEN__" ]; then
        cmd="NRC_ENTER-ONOFF"
    elif [ "$cmd" == "__OFF__" ]; then
	local avail=$(viera_is_available $deviceName)
	if [ "$avail" == "NO" ]; then
	    echo_log "viera_lookup_cmd: $deviceName is already turned off -> Abort"
            cmd=""
	else
            cmd="NRC_POWER-ONOFF"
	fi
    elif [ "$cmd" == "__PAUSE__" ]; then
        cmd="NRC_PAUSE-ONOFF"
    elif [ "$cmd" == "__PLAY__" ]; then
        cmd="NRC_PLAY-ONOFF"
    elif [ "$cmd" == "__NETFLIX__" ]; then
        cmd="NRC_NETFLIX-ONOFF"
    fi

    echo "$cmd"
    return 0
}

viera_send() {
    local deviceName=$1
    local cmd=$2

    if [ "$cmd" == "__ON__" ]; then
        local deviceMacs=${deviceList["$deviceName|macs"]}
        wolVerify "$deviceMacs"
        return
    fi
    
    
    ip=$(get_ip "$deviceName")
    if [ "$ip" == "0.0.0.0" ]; then
        echo "viera_send: No IP found for $deviceName"
        return 1
    fi 
    
    res=$(php-cgi -f $srcDir/TVremote.php action=$cmd ip=$ip)
    if [ ! -z "$(echo $res | grep 'Failed')" ]; then
        echo_log "viera_send: Sending to $deviceName Failed! Is the TV turned on?"
    fi
}

export -f viera_is_available
export -f viera_lookup_cmd
export -f viera_send
export -f viera_is_playing
