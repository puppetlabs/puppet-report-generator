#!/usr/bin/env ruby

require 'erb'
require 'yaml'
require 'rubygems'
require 'active_support'

def generate_hostname
  if @words.nil?
    @words = []
    File.open("/usr/share/dict/words").each_line do |line|
      @words << line.chomp
    end
    @words.delete_if {|word| word.length < 6 or word.squeeze != word or word.downcase != word}
  end

  @domain ||= @words.random_element
  @ext ||= ["net", "org", "com", "co.uk"].random_element

  host = @domain
  host = @words.random_element until host != @domain
  "#{host}.#{@domain}.#{@ext}"
end

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

5.times do
  hostname = generate_hostname
  puts hostname
  params = {
    :configuration_version => Time.now.to_i,
    :host => hostname,
    :status => "failed",
    :time => Time.now.to_yaml.chomp.gsub('--- ',''),
  }
  File.open("yaml/#{hostname}.yaml","w") do |f|
    f.write ERB.new(report_template).result(params.send(:binding))
  end
end
