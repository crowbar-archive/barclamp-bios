
# Copyright 2011, Dell


action :dump do 
  pgm = @new_resource.pgm
  dir = @new_resource.pgm_dir
  s = %x{ cd #{dir} ; #{pgm} setting show }
  Chef::Log.warn("Current token state: #{@new_resource.name} \n #{s}")
end
