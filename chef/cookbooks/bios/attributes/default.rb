# Copyright (c) 2011 Dell Inc.
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

default[:dell_bios][:config] = {}
default[:dell_bios][:config][:environment] = "bios-config-default"
default[:dell_bios][:debug] = false
default[:dell_bios][:bios_setup_enable] = true 
default[:dell_bios][:bios_update_enable] = true 

default[:crowbar][:hardware][:bios_set]= "Storage"
