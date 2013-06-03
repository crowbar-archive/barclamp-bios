#!/bin/bash
# Copyright (c) 2013 Dell Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

