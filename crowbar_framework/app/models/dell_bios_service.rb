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

  def initialize(thelogger)
    @bc_name = "dell_bios"
    @logger = thelogger
  end

  def create_proposal
    @logger.debug("DellBios create_proposal: entering")
    base = super
    @logger.debug("DellBios create_proposal: exiting")
    base
  end

  def transition(inst, name, state)
    a = [200, ""]
    @logger.debug("DellBios transition: enter #{name} for #{state}")
    #
    # If we are discovering the node, make sure that we add the bios role to the node
    #
    case state
    when "discovering"
      add_role(inst, name, state, "dell_bios_tools")
    when "discovered"
      add_role(inst, name, state, "dell_bios")
    end
  end

  def add_role(inst, name, state, new_role)
    @logger.debug("DellBios transition: installed state for #{name} for #{state}")
    db = Proposal.where(barclamp: "dell_bios", name: inst).first
    role = RoleObject.find_role_by_name "dell_bios-config-#{inst}"
    result = add_role_to_instance_and_node("dell_bios", inst, name, db, role, new_role )
    @logger.debug("DellBios transition: leaving from installed state for #{name} for #{state}")
    a = [200, NodeObject.find_node_by_name(name).to_hash ] if result
    a = [400, "Failed to add role to node"] unless result
    return a
  end

end
