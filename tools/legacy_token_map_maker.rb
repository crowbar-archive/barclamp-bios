#!/usr/bin/env ruby
# Copyright 2011, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

=begin
Process a csv file and produce setting maps. The expected format is:

token description set

where set can be:
- y:  include in default
- virt - include in virtualization set
- storage - include in storage set

=end

require 'csv'
require 'rubygems'
require 'json'

# Some fine day this will be real metadata
supported_bioses = {
  "PowerEdgeC2100" => ["C99Q3B22"], # The only one that is up to date
  "C6100" => ["1.64"], # The one we have is not even available for download.
  "PowerEdgeC6105" => ["1.7.9"] # Woefully out of date.
}

set_keys={
  "y" => ["default"],
  "virt"=> ["Virtualization"],
  "storage" => ["Storage","Hadoop"]
}

def clean_str(s)
  s.gsub(/[^a-zA-Z_0-9 ]/, "_").strip
end

supported_bioses.each_key do |sys|
  next unless File.exists?("maps/want-bios-options-#{sys}.csv")
  sets=Hash.new
  set_keys.each_key do |k|
    sets[k]=Hash.new
  end
  reader = CSV.open("maps/want-bios-options-#{sys}.csv","r")
  reader.shift
  reader.each do |row|
    token,setting,desc,want = row.map{|e|clean_str(e)}
    if set_keys[want]
      sets[want][setting] = [token,desc]
    else
      puts "maps/want-bios-options-#{sys}.csv: Unknown target set #{row.inspect}"
    end
  end
  reader.close
  set_keys.each do |k,v|
    v.each do |t|
      File.open("bios-set-#{sys}-#{t}.json","w") do |f|
        ob = { 
          "id" => "bios-set-#{sys}-#{t}",
          "versions" => supported_bioses[sys],
          "attributes" => sets[k]
        }
        f.puts(JSON.pretty_generate(ob))
      end
    end
  end
end
