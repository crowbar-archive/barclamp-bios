# Copyright (c) 2011 Dell Inc.
#

include_recipe "bios::bios-common"

def get_bag_item_safe (name, descr)
  data_bag_item("crowbar-data", name)
rescue
  Chef::Log.error("couldn't find #{descr} named #{name}")
  node["crowbar_wall"]["status"]["bios"] << "Could not find #{descr} named #{name}"
  nil
end

debug = node[:bios][:debug]
product = node[:dmi][:system][:product_name].gsub(/\s+/, '')
## hack for senile 6220...
product = "PowerEdgeC6220" if product =~ /DCS/
default_set = "bios-set-#{product}-default"
bios_set = get_bag_item_safe(default_set, "bios defaults")
bios_version = node[:dmi] && node[:dmi][:bios] && node[:dmi][:bios][:version]
style = bios_set && bios_set[:style] || "legacy"
style = "legacy" if style.length == 0
node[:bios][:style] = style
Chef::Log.info("Bios set style is: #{style}")

if !@@bios_setup_enable
  Chef::Log.info("Bios configuration disabled by user.")
elsif !bios_set
  Chef::Log.info("Unable to get default BIOS settings for #{product}")
  Chef::Log.info("Skipping BIOS configuration")
elsif (style != "wsman") && ! (
				bios_set[:versions] &&
				bios_set[:versions].kind_of?(Array) &&
				bios_set[:versions].member?(bios_version))
  Chef::Log.info("Skipping BIOS parameter setup for BIOS version #{bios_version}.")
  Chef::Log.info("For #{product}, we only know how to set parameters on BIOS versions #{bios_set[:versions].join(", ")}.")
else
  Chef::Log.info("Will configure #{product} BIOS #{bios_version} parameters")
  case style
  when "legacy","new_pec","unified_pec"
    # Run the statically linked version of setupbios on the ubuntu platform
    pgm_dir = "/opt/bios/setupbios"
    pgmname = "#{pgm_dir}/alternate_version/setupbios.static"
    # if we don't have the BIOS utility, we can't setup anything...
    ruby_block "check for setupbios" do
      block do
	unless File.exists?(pgmname)
	  @@bios_setup_enable = false
	  node["crowbar_wall"]["status"]["bios"] << "Could not find #{pgmname}: Disabling setup"
	end
      end
    end
  end

  ## try to get the per-role set name.
  ## look for role+platform specific, and if not found, use role only.
  ## if neither found, use just defualts.
  bios_set_name = node[:crowbar][:hardware][:bios_set]
  setname = "bios-set-#{product}-#{bios_set_name}"
  bios_over = get_bag_item_safe(setname, " overrides for #{setname} ")
  if bios_over.nil?
    setname = "bios-set-#{bios_set_name}"
    bios_over = get_bag_item_safe(setname, " overrides for #{setname} ")
  end

  if bios_over.nil?
    log("no role overide settings, setting to defaults" ) { level :warn}
    values = bios_set["attributes"].dup
  else
    log("using role overide settings from: #{setname}") { level :warn}
    # WSMAN needs a deep merge!
    if style == "wsman"
      # overlay[fqdd][groups][attr_names] = values (value is a hash)
      bios_over["attributes"].each do |k, groups|
	if bios_set["attributes"][k]
	  groups.each do |group, attrs|
	    if bios_set["attributes"][k][group]
	      bios_set["attributes"][k][group] = bios_set["attributes"][k][group].merge(attrs)
	    else
	      bios_set["attributes"][k][group] = attrs
	    end
	  end
	else
	  bios_set["attributes"][k] = groups
	end
      end
      values = bios_set["attributes"]
    else
      values = bios_set["attributes"].merge(bios_over["attributes"])
    end
  end

  case  style
  when "wsman"
    bios_configure "wsman" do
      type           "wsman"
      product         node[:dmi][:system][:product_name]
      max_tries       node[:bios][:max_tries]
      values          values
      problem_file "/var/log/chef/hw-problem.log"
      action   :configure
    end
  when "unified_pec"
    values.each do |name,val|
      if name == "raw_tokens"
        val.each do |tok|
          tok = sprintf("%x",tok)
          bash "set raw D4 token #{tok}" do
            cwd pgm_dir
            code "#{pgmname} set #{tok}"
          end
        end
      else
        bash "set #{name} to #{val}" do
          cwd pgm_dir
          code "#{pgmname} setting set #{name} #{val}"
        end
      end
    end
  when "new_pec"
    values.each { | name, set_value|
      log("setting #{name} to #{set_value}")
      bash "bios-update-#{name}" do
	cwd pgm_dir
	code <<-EOH
	   #{pgmname} setting set #{name} #{set_value}
	 EOH
      end
    }
  when "legacy"
    bios_tokens "before changes" do
      action :dump
      pgm pgmname
      pgm_dir pgm_dir
    end if debug

    values.each { | name, set_value|
      d4_token = set_value[0]
      bash "bios-update-#{name}-#{d4_token}-#{name}" do
	cwd pgm_dir
	code <<-EOH
	   echo #{pgmname} set #{d4_token}
	   #{pgmname} set #{d4_token}
	 EOH
      end
    }

    bios_tokens "after changes" do
      action :dump
      pgm pgmname
      pgm_dir pgm_dir
    end if debug
  end
end
node.save
