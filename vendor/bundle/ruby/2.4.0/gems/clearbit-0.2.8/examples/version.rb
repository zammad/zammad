require 'clearbit'
require 'pp'

Clearbit::Enrichment::PersonCompany.version = '2015-05-30'

p Clearbit::Enrichment::PersonCompany.find(email: 'alex@clearbit.com', webhook_url: 'http://requestb.in/18owk611')
