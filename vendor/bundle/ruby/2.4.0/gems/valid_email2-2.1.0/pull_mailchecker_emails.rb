#!/usr/bin/env ruby

require "yaml"

require "json"
require "net/http"

whitelisted_emails = %w(poczta.onet.pl fastmail.fm hushmail.com hush.ai hush.com hushmail.me naver.com qq.com example.com)

existing_emails = YAML.load_file("vendor/disposable_emails.yml")

url = "https://raw.githubusercontent.com/FGRibreau/mailchecker/master/list.json"
resp = Net::HTTP.get_response(URI.parse(url))

remote_emails = JSON.parse(resp.body).flatten - whitelisted_emails

result_emails = (existing_emails + remote_emails).map(&:strip).uniq.sort

File.open("vendor/disposable_emails.yml", "w") {|f| f.write result_emails.to_yaml }
