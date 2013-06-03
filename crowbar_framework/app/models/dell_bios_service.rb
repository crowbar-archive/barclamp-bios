# Copyright 2013, Dell
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

class DellBiosService < ServiceObject
  
  def transition(inst, name, state)
    a = [200, ""]
    @logger.debug("DellBios transition: enter #{name} for #{state}")
    
    #
    # If we are discovering the node, make sure that we add the bios role to the node
    #
    if state == "discovered"
      @logger.debug("DellBios transition: installed state for #{name} for #{state}")
      result = add_role_to_instance_and_node(name, inst, "dell_bios")
      @logger.debug("DellBios transition: leaving from installed state for #{name} for #{state}")
      a = result ? [200, ""] : [400, "Failed to add role"] # GREG: TRANSLATE
    end
    
    @logger.debug("DellBios transition: leaving for #{name} for #{state}")
    a
  end
  
end
