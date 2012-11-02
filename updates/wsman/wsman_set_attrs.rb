#!/usr/bin/ruby

require 'wsman'
require 'wsman_attributes'

opts = { :host => ARGV[0], :user => ARGV[1], :password => ARGV[2], :port => 443, :debug_time => false }
attrs = {}

count=ARGV.length - 3
count.times do |i|
  parts = ARGV[i + 3].split("=")
  attrs[parts[0]] = parts[1]
  puts "GREG: setting #{parts[0]} to #{parts[1]}"
end

answer, message, node = test_set_attributes(attrs, opts)

puts "answer = #{answer}"
puts "message = #{message}"

