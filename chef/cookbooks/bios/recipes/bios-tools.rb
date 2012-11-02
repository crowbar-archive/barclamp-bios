#
# Copyright (c) 2011 Dell Inc.
#
#
#  Ensure that tools required to work with BIOS are installed.
# (Applies both to PEC and WSMAN variants)
#

include_recipe "bios::bios-common"

bmc="bmc-2012-08-31.tgz"
setupbios="setupbios-2012-08-16.tgz"
socflash="socflash_v10601.zip"


###
# these gems will be loaded by chef providers.. 
# so make sure they're installed early
%w{libxml-ruby xml-simple}.each { |pkg|
  a = gem_package pkg
  a.run_action(:install)
}

# These are tools that we rely on to configure PEC gear.
[bmc,setupbios,socflash].each do |f|
  a = remote_file "/tmp/#{f}" do
    source "#{@@provisioner_server}/files/dell_bios/tools/#{f}"
    action :nothing
  end
  a.run_action(:create_if_missing)
end

a = bash "Extract #{bmc}" do
  code <<EOC
if [[ ! -x /usr/bin/bmc ]]; then
    cd /usr/bin; tar xzf /tmp/#{bmc} bmc
fi
EOC
  action :nothing
end
a.run_action(:run)

a = bash "Extract #{setupbios}" do
  code <<EOC
mkdir -p /opt/bios
cd /opt/bios
[[ -x setupbios/setupbios ]] || tar xzf /tmp/#{setupbios}
EOC
  action :nothing
end
a.run_action(:run)

a = bash "Extract #{socflash}" do
  code <<EOC
cd /tmp
[[ -d v10601 ]] || unzip #{socflash}
if [[ ! -x /usr/bin/socflash_x64 ]]; then
    cd /usr/bin
    tar xzf /tmp/v10601/lxflash_v10601.tar.gz socflash_x64
fi
EOC
  action :nothing
end
a.run_action(:run)
