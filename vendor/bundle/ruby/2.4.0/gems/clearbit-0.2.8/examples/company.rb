require 'clearbit'
require 'pp'

pp Clearbit::Enrichment::Company.find(domain: 'stripe.com', stream: true)
