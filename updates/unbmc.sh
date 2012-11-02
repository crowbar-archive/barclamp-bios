#!/bin/bash

timed() {
    local deadline=$(($(date '+%s') + 60))
    echo "running $@" 
    ( $@ ) &
    
    local testpid=$!
    (   cd /proc/$testpid
	while [[ -f cmdline ]] && (($(date '+%s') <= $deadline)); do
	    sleep 1
	    echo "."
	done
	if  [[ -f "/proc/$testpid/cmdline" ]]; then
	    echo "killing $testpid"
	    kill -TERM "$testpid"
	    fi
    )
}

timed modprobe ipmi_si
timed modprobe ipmi_devintf
 
ipmitool power status || socflash_x64 option=r of=/dev/null

rmmod ipmi_si
rmmod ipmi_devintf
rmmod ipmi_msghandler

