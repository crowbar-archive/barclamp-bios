# Copyright (c) 2013 Dell Inc.
# Copyright (c) 2014 SUSE Linux GmbH.
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

# Common BIOS methods which get executed on both the install and update
# phase.

include_recipe "utils"

node["crowbar_wall"] = {} if node["crowbar_wall"].nil?
node["crowbar_wall"]["status"] = {} if node["crowbar_wall"]["status"].nil?
node["crowbar_wall"]["status"]["bios"] = []

@@debug = node[:dell_bios][:debug]

centos = node.platform_family == "redhat"
ubuntu = node.platform == "ubuntu"

log("BIOS: running on OS:[#{platform}] on #{node[:dmi][:system][:product_name]} hardware") { level :info}


## enforce platform limitations
@@bios_setup_enable = node[:dell_bios][:bios_setup_enable] & centos & !CrowbarHelper.is_admin?(node)
@@bios_update_enable = node[:dell_bios][:bios_update_enable] & centos & !CrowbarHelper.is_admin?(node)
@@bmc_update_enable = node[:dell_bios][:bmc_update_enable] & centos & !CrowbarHelper.is_admin?(node)


node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using centos:#{centos} ubuntu:#{ubuntu}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using setup_enabled = #{@@bios_setup_enable}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using bios_update_enabled = #{@@bios_update_enable}"
node["crowbar_wall"]["status"]["bios"] << "Bios Barclamp using bmc_update_enabled = #{@@bmc_update_enable}"
node.save

