#!/usr/bin/env bash
srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $srcDir/ha.sh

echo_log "executing connection check"

update_all
/bin/bash $srcDir/mactoip.sh update
