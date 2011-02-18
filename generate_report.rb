#!/usr/bin/env ruby

require 'erb'
require 'yaml'

report_template = <<REPORT_TEMPLATE
--- !ruby/object:Puppet::Transaction::Report
  configuration_version: <%= params[:configuration_version] %>
  host: <%= params[:host] %>
  kind: apply
  logs: []
  metrics: {}
  puppet_version: 2.6.5
  report_format: 2
  resource_statuses: {}
  status: <%= params[:status] %>
  time: <%= params[:time] %>
REPORT_TEMPLATE


$ARGV.each_with_index do |hostname,index|
  params = {
    :configuration_version => Time.now.to_i,
    :host => hostname,
    :status => "failed",
    :time => Time.now.to_yaml.chomp.gsub('--- ',''),
  }
  File.open("yaml/#{index}.yaml","w") do |f|
    f.write ERB.new(report_template).result(params.send(:binding))
  end
end
