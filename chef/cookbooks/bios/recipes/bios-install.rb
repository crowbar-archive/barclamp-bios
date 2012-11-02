# Copyright (c) 2011 Dell Inc.

include_recipe "bios::bios-common"

return unless @@provisioner_server

include_recipe "bios::bios-tools"

problem_file = "/var/log/chef/hw-problem.log"
product = node[:dmi][:system][:product_name]
product.strip!
%w{bios bmc}.each do |t|
  next unless (node["bios"]["updaters"][product][t] rescue nil)
  f = node["bios"]["updaters"][product][t]
  if f.include?('/')
    directory "/tmp/#{f.split('/')[0..-1].join('/')}" do
      recursive true
    end
  end
  remote_file "/tmp/#{f}" do
    source "@@provisioner_server/files/dell_bios/#{f}"
    mode '0755'
    action :create_if_missing
    ignore_failure true
  end
end

bios_update "bmc" do
  type            "bmc"
  problem_file    problem_file
  product         product
  max_tries       node[:bios][:max_tries]
  only_if         { @@bmc_update_enable }
  action   :update
end


bios_update "bios" do
  type            "bios"
  problem_file    problem_file
  product         product
  max_tries       node[:bios][:max_tries]
  only_if         { @@bios_update_enable }
  action   :update
end

bios_update "wsman" do
  type           "wsman"
  problem_file    problem_file
  product         product
  max_tries       node[:bios][:max_tries]
  only_if         { @@bios_update_enable }
  action   :update
end
