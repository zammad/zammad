require 'uri'

module Helpers
  def response_double(opts={})
    double('response', {:to_hash => {}}.merge(opts))
  end

  def fake_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end

  def request_double(url: 'http://example.com', method: 'get')
    double('request', url: url, uri: URI.parse(url), method: method,
           user: nil, password: nil, cookie_jar: HTTP::CookieJar.new,
           redirection_history: nil, args: {url: url, method: method})
  end
end
