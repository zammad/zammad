VCR.configure do |config|
  config.cassette_library_dir = 'test/data/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  config.ignore_localhost = true
  config.ignore_request do |request|
    uri = URI(request.uri)

    ['zammad.com', 'google.com'].any? do |site|
      uri.host.include?(site)
    end
  end
end
