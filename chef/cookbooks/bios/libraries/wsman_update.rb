#!/usr/bin/ruby
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

require 'rubygems'
require 'xmlsimple'
require 'yaml'
require 'json'

class Crowbar
class BIOS

class WSMANUpdate
  def initialize(wsman)
    @wsman = wsman
  end

  def software_inventory
    output = @wsman.command("enumerate", 
               "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_SoftwareIdentity", 
               "-m 256")
    return false unless output

    hash = {}
    @wsman.measure_time "WSMAN enumerate inventory parse" do
      hash = XmlSimple.xml_in(output, "ForceArray" => false)
    end
    hash["Body"]["EnumerateResponse"]["Items"]["DCIM_SoftwareIdentity"]
  end

  # Example: Find iDRAC6
  # list2 = find_software_inventory_items(list, 
  #           {"ElementName" => "iDRAC.*", "ComponentType" => "FRMW", "Status" => "Installed"})
  #
  def find_software_inventory_items(inventory, test = {})
    return inventory if test.size == 0
    inventory.select do |x| 
      found = true
      test.each { |k,v| 
        found = false unless x[k] =~ /#{v}/
      }
      found
    end
  end

  def software_installation_service
    output = @wsman.command("enumerate", 
               "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_SoftwareInstallationService",
               "-m 256")
    return false unless output

    hash = {}
    @wsman.measure_time "WSMAN parse SI values" do
      hash = XmlSimple.xml_in(output, "ForceArray" => false)
    end
    t = hash["Body"]["EnumerateResponse"]["Items"]["DCIM_SoftwareInstallationService"]
    [ t["CreationClassName"], t["SystemCreationClassName"], t["SystemName"], t["Name"] ]
  end

  def do_update(id, uri)
    ccn, sccn, sn, n = self.software_installation_service

    # Dump request file
    File.open("/tmp/request.xml", "w+") do |f|
      f.write %Q[
<p:InstallFromURI_INPUT xmlns:p="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_SoftwareInstallationService">
  <p:URI>#{uri}</p:URI>
  <p:Target xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
    <a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:Address>
    <a:ReferenceParameters>
      <w:ResourceURI>http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_SoftwareIdentity</w:ResourceURI>
      <w:SelectorSet>
        <w:Selector Name="InstanceID">#{id}</w:Selector>
      </w:SelectorSet>
    </a:ReferenceParameters>
  </p:Target>
</p:InstallFromURI_INPUT>
]
    end
  
    # Post the update request.
    output = @wsman.command("invoke -a InstallFromURI", 
               "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_SoftwareInstallationService?CreationClassName=#{ccn},SystemCreationClassName=#{sccn},SystemName=#{sn},Name=#{n}", 
               "-J /tmp/request.xml")
    return false unless output

    hash = XmlSimple.xml_in(output, "ForceArray" => false)
    t = hash["Body"]["InstallFromURI_OUTPUT"]

    puts "Debug: Install URI hash = #{hash.inspect}"

    # Some versions don't actually give a return code on success.
    if t["ReturnValue"].instance_of? Hash
      return true, t["Job"]["ReferenceParameters"]["SelectorSet"]["Selector"][0]["content"]
    end

    if t["ReturnValue"].to_i == 4096
      return true, t["Job"]["ReferenceParameters"]["SelectorSet"]["Selector"][0]["content"]
    end

    return false, t["Message"]
  end

  #
  # update the id to the uri
  # return true,reboot on success where reboot is true or false if reboot is needed.
  # return false, message on failure.
  #
  def update(id, uri)
    answer, jid = self.do_update(id, uri)
    if answer
      # Loop until we get something interesting.
      new_count = 0
      answer, status = @wsman.get_job_status(jid)
      while answer and (status != "Downloaded" and status != "Failed" and status != "Completed")
        if status == "New"
          new_count = new_count + 1
        else
          new_count = 0
        end
        # If we are stuck in New, reboot and see if that fixes it.
        return false, true if new_count > 36
        sleep 10
        answer, status = @wsman.get_job_status(jid)
      end
      # If we completed, we are done.
      if status == "Completed"
        return true, false 
      end
      if status == "In Use"
        return true, true # Force a reboot
      end
      # If we didn't fail, we need to schedule the job and reboot.
      if status != "Failed"
        answer, status = @wsman.schedule_job(jid, "TIME_NOW")
        return answer, true
      end
      # Set error message
      jid = status
    end
    return false, jid
  end

  def match(pieces, c)
    if c["VendorID"].instance_of? String
      pieces.each do |pkg, data|
        data["devices"].each do |device|
          next unless device["vendorID"]
          next unless device["deviceID"]
  
          unless device["subDeviceID"] and device["subDeviceID"] == "" and
                 device["subVendorID"] and device["subVendorID"] == ""
            sub_truth = c["SubDeviceID"].downcase == device["subDeviceID"].downcase and
                        c["SubVendorID"].downcase == device["subVendorID"].downcase 
          else
            sub_truth = true
          end
  
          return data if c["DeviceID"].downcase == device["deviceID"].downcase and
                         c["VendorID"].downcase == device["vendorID"].downcase and
                         sub_truth
        end
      end
    else
      pieces.each do |pkg, data|
        data["devices"].each do |device|
          return data if c["ComponentID"].downcase == device["componentID"].downcase
        end
      end
    end
    nil
  end

  #
  # Assumes hash with compID => file
  # Returns list with [ [CompID, file], ...]
  #
  # Sorts - files with LC first, BIOS second, IDRAC last
  #
  def sort_updates(updates)
    return updates if updates.nil? or updates.size == 0


    ans = updates.sort do |a,b|
      af = a[1]
      bf = b[1]

      aflc = (af =~ /LC/ ? true : false)
      bflc = (bf =~ /LC/ ? true : false)
      afb = (af =~ /BIOS/ ? true : false)
      bfb = (bf =~ /BIOS/ ? true : false)
      afd = (af =~ /DRAC/ ? true : false)
      bfd = (bf =~ /DRAC/ ? true : false)

      ans = -5
      # if they are the same, compare normal
      ans = af <=> bf if (aflc and bflc) or (afb and bfb) or (afd and bfd)

      # if they are LC, they should be first
      ans = -1 if (aflc and not bflc) and ans == -5
      ans = 1 if (not aflc and bflc) and ans == -5

      # if they are BIOS, they should be next
      ans = -1 if (afb and not bfb) and ans == -5
      ans = 1 if (not afb and bfb) and ans == -5

      # if they are DRAC, they should be last
      ans = 1 if (afd and not bfd)
      ans = -1 if (not afd and bfd) and ans == -5

      # Default action
      ans = af <=> bf if ans == -5
      ans
    end

    ans
  end
end

end
end

#######################################################

#
# Assumes that supported.json has been returned
#
def test_update(opts)
  require 'wsman'
  sys = %x{dmidecode -t system | grep "Product Name:" | awk -F: '{ print $2 }'}.strip!
  puts "System: #{sys}"

  system("wget -q http://#{opts[:prov_ip]}:#{opts[:prov_port]}/files/wsman/supported.json -O /tmp/supported.json")
  jsondata = File.read('/tmp/supported.json')
  data = JSON.parse(jsondata)
  unless data
    puts "Failed to load the supported file"
    exit 1
  end

  pieces = data[sys]
  unless pieces
    puts "Failed to find sys"
    exit 1
  end
  wsman = Crowbar::WSMAN.new(opts)
  wsman_update = Crowbar::BIOS::WSMANUpdate.new(wsman)

  list = wsman_update.software_inventory
  list2 = wsman_update.find_software_inventory_items(list, {"Status" => "Installed"})

  updates = {}
  list2.each do |c|
    if k = wsman_update.match(pieces, c)
      if c["VersionString"] == k["version"]
        puts "Already at correct version: #{c["ElementName"]}"
        next
      end

      updates[c["InstanceID"]] = k["file"]
    else
      puts "No update for #{c["ElementName"]} #{c["ComponentID"]}"
    end
  end

  # Sort the updates.
  updates = wsman_update.sort_updates(updates)

  # Clear jobs
  answer, status = wsman.clear_all_jobs
  if !answer
    return false, status
  end

  # Do the updates
  updates.each do |d|
    id = d[0]
    file = d[1]
    puts "Update: #{id} #{file}"
    answer, jid = wsman_update.update(id, "http://#{opts[:prov_ip]}:#{opts[:prov_port]}/files/#{file}")
    if answer
      puts "Job scheduled ready for reboot" if jid
      puts "Job completed" unless jid
    else
      puts "update failed: #{jid}"
    end
  end

end
