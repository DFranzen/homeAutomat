srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

load_config() {
    if ! ([[ -v devices[@] ]] && [[ -v deviceList[@] ]]); then
	echo_log "reloading config"
	. $srcDir/ha.conf
	if ! ([[ -v devices[@] ]] && [[ -v deviceList[@] ]]); then
	    echo_log "config still not loaded"
	fi
	
    fi
}

getbc_ip() {
    echo $(sudo -u $ha_user ifconfig | grep -A5 "$primary_iface"| grep -oE "(Bcast|broadcast)[: ]([0-9]{1,3}\.){3}[0-9]{1,3}"|grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
}

macList2Ip() {
    macList=$1
    IFS='|' read -r -a macs <<< $macList

    ip=""
    
    for index in "${!macs[@]}"
    do
	ip="0.0.0.0"
	mac=${macs[index]}
	if [[ $mac =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	    echo "$mac"
	    return 0
	fi
	echo_log "trying MAC $mac"
	ip=$(bash $srcDir/mactoip.sh lookup $mac)
	
	if [ "$ip" == "0.0.0.0" ]; then
	    #ip not known
	    echo_log "no IP found for MAC $mac"
	    continue;
	fi
	echo_log "found ip $ip for mac $mac, checking if alive"
	echo "$ip"
	return 0
    done
    echo "$ip"
    return 1
}

wolVerify() {
    macList="$1"
    echo_log "Waking $macList"
    #ip=$(macList2Ip "$macList")
    IFS='|' read -r -a macs <<< "$macList"
    bc_ip=$(getbc_ip)
    #echo_log "got ip $ip"

    for index in "${!macs[@]}"; do
	mac=${macs[index]}
	wakeonlan -i $bc_ip $mac
    done
}
	
echo_log() {
    echo "$(date +"%T") $1" >> $srcDir/log.txt
}
       
export -f echo_log
export -f wolVerify
export -f macList2Ip
export -f getbc_ip
export -f load_config
