require 'clearbit'
require 'csv'

puts 'domain,fuzzy'

STDIN.read.each_line do |line|
  result = Clearbit::Reveal.find(ip: line.strip)
  next puts unless result
  puts CSV.generate_line([result.domain, result.fuzzy])
end

