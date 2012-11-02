#!/usr/bin/ruby

require 'rubygems'
require 'chef'
require 'wsman'
require 'wsman_attributes'

opts = { :host => ARGV[0], :user => ARGV[1], :password => ARGV[2], :port => 443, :debug_time => false }
test_build_config_json(opts)

