VCR.configure do |config|
  config.cassette_library_dir = 'test/data/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  config.ignore_localhost = true
  config.ignore_request do |request|
    uri = URI(request.uri)

    ['zammad.com', 'google.com', 'elasticsearch', 'selenium'].any? do |site|
      uri.host.include?(site)
    end
  end

  config.register_request_matcher(:oauth_headers) do |r1, r2|
    without_onetime_oauth_params = ->(params) { params.gsub(/oauth_(nonce|signature|timestamp)="[^"]+", /, '') }

    r1.headers.except('Authorization') == r2.headers.except('Authorization') &&
      r1.headers['Authorization']&.map(&without_onetime_oauth_params) ==
        r2.headers['Authorization']&.map(&without_onetime_oauth_params)
  end
end
