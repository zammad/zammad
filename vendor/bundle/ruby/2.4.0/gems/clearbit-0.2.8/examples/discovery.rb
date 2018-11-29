require 'clearbit'
require 'pp'

pp Clearbit::Discovery.search(query: {tech: 'marketo'})
