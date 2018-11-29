require 'nestful'
require 'csv'

page_speed = Nestful::Mash.get(
  'https://www.googleapis.com/pagespeedonline/v1/runPagespeed',
  url: 'http://monocle.io',
  key: ENV['GOOGLE_SECRET']
)

CSV.open('stats.csv', 'a') do |csv|
  csv << [Time.now, page_speed.score, *page_speed.pageStats.values]
end