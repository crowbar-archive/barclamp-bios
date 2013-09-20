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

grep -i "vmware virtual platform\|virtualbox" /sys/class/dmi/id/product_name
if [ $? -eq 0 ]; then
    echo "Not flashing BMC ... unsupported platform (virtual)"
    return 0
fi

if [[ $1 = ubuntu-12.04 ]]; then
    timed modprobe ipmi_si
fi

timed modprobe ipmi_devintf
 
ipmitool power status 
if [ $? -ne 0 ]; then
    /updates/socflash_x64 option=r of=/dev/null
fi 

rmmod ipmi_devintf

if [[ $1 = ubuntu-12.04 ]]; then
    rmmod ipmi_si
    rmmod ipmi_msghandler
fi

