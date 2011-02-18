#!/usr/bin/env ruby

require 'generate_report'

unless ARGV.length > 0
  puts "Specify the rakefile to use"
  exit 1
end

rakefile = ARGV.first

100.times do
  generate_report
end

puts "Importing reports"
`rake -f #{rakefile} reports:import REPORT_DIR=yaml`

10.times do
  puts `rake -f #{rakefile} node:add name=#{generate_hostname}`
end

