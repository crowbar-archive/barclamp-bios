#
# Copyright (c) 2011 Dell Inc.
#

# Common BIOS methods which get executed on both the install and update
# phase.

include_recipe "utils"

node["crowbar_wall"] = {} if node["crowbar_wall"].nil?
node["crowbar_wall"]["status"] = {} if node["crowbar_wall"]["status"].nil?
node["crowbar_wall"]["status"]["bios"] = []

@@debug = node[:bios][:debug]

log("BIOS: running on OS:[#{node[:platform]}] on #{node[:dmi][:system][:product_name]} hardware") { level :info} 


## enforce platfrom limitations
@@bios_setup_enable = node[:bios][:bios_setup_enable] && @@centos && !@@is_admin
@@bios_update_enable = node[:bios][:bios_update_enable] && @@centos && !@@is_admin
@@bmc_update_enable = node[:bios][:bmc_update_enable] && @@centos && !@@is_admin


node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using centos:#{@@centos} ubuntu:#{@@ubuntu}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using setup_enabled = #{@@bios_setup_enable}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using bios_update_enabled = #{@@bios_update_enable}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using bmc_update_enabled = #{@@bmc_update_enable}"
node.save

