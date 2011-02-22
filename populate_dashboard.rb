#!/usr/bin/env ruby

require 'generate_report'
require 'rubygems'

rakefile_if_specified = "-f #{ARGV.first}" unless ARGV.empty?

100.times do
  report = DataGenerator.generate_report
  File.open("yaml/#{report.host}.yaml","w") do |f|
    f.print report.to_yaml
  end
end

puts "Importing reports"
`rake #{rakefile_if_specified} reports:import REPORT_DIR=yaml`

puts "Creating unresponsive nodes"
10.times do
  puts `rake #{rakefile_if_specified} node:add name=#{generate_hostname}`
end

