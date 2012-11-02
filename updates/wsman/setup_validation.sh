#!/bin/bash

# Run from admin node

cd /root
cp -r /updates/wsman .
cp /opt/dell/barclamps/bios/chef/cookbooks/bios/libraries/* /root/wsman

rpm -Uvh /opt/dell/barclamps/bios/wsman/libwsman1-2.2.7-1.x86_64.rpm
rpm -Uvh /opt/dell/barclamps/bios/wsman/wsmancli-2.2.7.1-11.x86_64.rpm 

