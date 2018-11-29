require 'clearbit'
require 'pp'

pp Clearbit::Enrichment.find(email: 'alex@alexmaccaw.com')
