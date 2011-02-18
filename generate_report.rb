#!/usr/bin/env ruby

require 'erb'
require 'yaml'
require 'ostruct'
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

def generate_time
  time = Time.now
  time -= 1.day if rand(100) < 5
  time.to_yaml.chomp.gsub('--- ','')
end

def generate_report
  @report_template ||= File.read("report_template.yaml.erb")
  hostname = generate_hostname
  params = OpenStruct.new({
    :configuration_version => Time.now.to_i,
    :hostname => hostname,
    :time => generate_time,
  })
  resources = []
  3.times do
    resources << generate_resource(params)
  end
  params.status = if resources.any? {|res| res.failed}
                    "failed"
                  elsif resources.any? {|res| res.change_count > 0}
                    "changed"
                  else
                    "unchanged"
                  end
  params.resource_string = resources.map do |res|
    ERB.new(@resource_template).result(res.send(:binding))
  end.join.chomp

  File.open("yaml/#{hostname}.yaml","w") do |f|
    f.write ERB.new(@report_template).result(params.send(:binding))
  end
  #puts ERB.new(@report_template).result(params.send(:binding))
end

def generate_resource(report_params)
  @resource_template = <<RESOURCE
    "<%= resource_type %>[<%= title %>]": !ruby/object:Puppet::Resource::Status
      change_count: <%= change_count %>
      changed: <%= change_count > 0 %>
      evaluation_time: <%= evaluation_time %>
      events: []
      failed: <%= failed %>
      file: /etc/puppet/manifests/site.pp
      line: <%= rand(250)+1 %>
      out_of_sync: <%= out_of_sync_count > 0 %>
      out_of_sync_count: <%= out_of_sync_count %>
      resource: "<%= resource_type %>[<%= title %>]"
      resource_type: <%= resource_type %>
      skipped: false
      tags: 
        - <%= resource_type.downcase %>
        - node
        - <%= hostname %>
        - class
        - <%= title.downcase %>
      time: <%= time %>
      title: <%= title %>
RESOURCE

  params = OpenStruct.new
  params.resource_type = "File"
  params.title = File.join("/", (1..(rand(5)+2)).map {@words.random_element})
  params.change_count = rand(100) < 80 ? 0 : rand(5)+1
  params.evaluation_time = Time.now.to_f % 1 + rand(3)
  params.out_of_sync_count = params.change_count
  params.hostname = report_params.hostname
  params.time = report_params.time
  params.failed = params.change_count > 0 && rand(100) < 10

  params
end
