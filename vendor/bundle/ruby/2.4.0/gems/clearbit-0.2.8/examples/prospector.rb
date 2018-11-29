require 'clearbit'
require 'pp'

people = Clearbit::Prospector.search(domain: 'clearbit.com')

people.each do |person|
  puts [person.name.full_name, person.email]
end
