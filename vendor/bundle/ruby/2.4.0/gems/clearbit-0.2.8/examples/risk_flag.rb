require 'clearbit'
require 'pp'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: risk_flag.rb [options]"

  opts.on("-iIP", "--ip=IP", "IP address") do |ip|
    options[:ip] = ip
  end

  opts.on("-eEMAIL", "--email=EMAIL", "Email address") do |email|
    options[:email] = email
  end

  opts.on("-tTYPE", "--type=TYPE", "Type") do |type|
    options[:type] = type
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

options[:type] ||= 'spam'

begin
  Clearbit::Risk.flag(options)
rescue Nestful::Error => err
  pp err.decoded
else
  puts 'Successfully flagged!'
end
