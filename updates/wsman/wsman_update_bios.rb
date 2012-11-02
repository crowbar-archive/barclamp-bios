#!/usr/bin/ruby

require 'wsman'
require 'wsman_update'

opts = { :prov_ip => (ARGV[3] || "192.168.124.10"), :prov_port => (ARGV[4] || "8091").to_i,
         :host => ARGV[0], :port => 443, 
         :user => ARGV[1], :password => ARGV[2], 
         :debug_time => false }
test_update(opts)

