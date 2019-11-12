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

RSpec.configure do |config|
  config.around(:each, use_vcr: true) do |example|
    spec_path       = Pathname.new(example.file_path).realpath
    cassette_path   = spec_path.relative_path_from(Rails.root.join('spec')).sub(/_spec\.rb$/, '')
    cassette_name   = "#{example.example_group.description} #{example.description}".gsub(/[^0-9A-Za-z.\-]+/, '_').downcase
    request_profile = case example.metadata[:use_vcr]
                      when true
                        %i[method uri]
                      when :with_oauth_headers
                        %i[method uri oauth_headers]
                      end

    VCR.use_cassette(cassette_path.join(cassette_name), match_requests_on: request_profile) do
      example.run
    end
  end
end
