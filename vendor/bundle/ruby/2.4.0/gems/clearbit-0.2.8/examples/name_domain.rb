require 'clearbit'
require 'pp'

pp Clearbit::NameDomain.find(name: 'Stripe')
