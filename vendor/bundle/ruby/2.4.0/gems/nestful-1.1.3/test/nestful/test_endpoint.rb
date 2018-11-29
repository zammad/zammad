require 'test_helper'

class TestEndpoint < Minitest::Test
  def test_join
    endpoint = Nestful::Endpoint['http://example.com']['charges'][1]
    assert_equal 'http://example.com/charges/1', endpoint.url
  end

  def test_get
    stub_request(:any, 'http://example.com/charges?limit=10')
    Nestful::Endpoint['http://example.com']['charges'].get(:limit => 10)
    assert_requested(:get, 'http://example.com/charges?limit=10')
  end

  def test_post
    stub_request(:any, 'http://example.com/charges')
    Nestful::Endpoint['http://example.com']['charges'].post
    assert_requested(:post, 'http://example.com/charges')
  end
end
