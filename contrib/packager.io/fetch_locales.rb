#!/usr/bin/env ruby
# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rubygems'
require 'uri'
require 'net/http'
require 'json'
require 'yaml'

version = File.read('VERSION')
version.strip!

url_locales = 'https://i18n.zammad.com/api/v1/locales'
url_translations = 'https://i18n.zammad.com/api/v1/translations/'

file_locales = "config/locales-#{version}.yml"
directory_translations = 'config/translations'

# download locales
uri = URI.parse("#{url_locales}?version=#{version}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Get.new(uri)
response = http.request(request)
data = JSON.parse(response.body)

puts "Writing #{file_locales}..."
File.open(file_locales, 'w') do |out|
  YAML.dump(data, out)
end

# download translations
if !File.directory?(directory_translations)
  Dir.mkdir(directory_translations, 0o755)
end
data.each do |locale|
  url = "#{url_translations}#{locale['locale']}?version=#{version}"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri)
  response = http.request(request)
  data = JSON.parse(response.body)
  file = "#{directory_translations}/#{locale['locale']}-#{version}.yml"
  puts "Writing #{file}..."
  File.open(file, 'w') do |out|
    YAML.dump(data, out)
  end
end
puts 'done'
