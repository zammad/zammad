require 'clearbit'
require 'pp'

pp Clearbit::Enrichment::Person.find(email: 'alex@alexmaccaw.com')
