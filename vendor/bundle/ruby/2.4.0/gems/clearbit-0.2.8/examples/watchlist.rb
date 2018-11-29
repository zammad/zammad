require 'clearbit'
require 'pp'

pp Clearbit::Watchlist.search(name: 'Smith')