require 'test_helper'

class TestResource < Minitest::Test
  class Charge < Nestful::Resource
    endpoint 'http://example.com'
    path '/v1/charges'
  end

  class Token < Nestful::Resource
    endpoint 'http://example.com'
    path '/v1/tokens'
    defaults :params => {:one => 1}
  end

  def setup
  end

  def test_get
    stub_request(:any, 'http://example.com/v1/charges').to_return(:body => '')
    Charge.get
    assert_requested(:get, 'http://example.com/v1/charges')
  end

  def test_post
    stub_request(:any, 'http://example.com/v1/charges/unknown').to_return(:body => '')
    Charge.post 'unknown'
    assert_requested(:post, 'http://example.com/v1/charges/unknown')
  end

  def test_get_json
    stub_request(:any, 'http://example.com/v1/charges/1').to_return(
      :body => '{"id": 1, "amount": 2000}',
      :headers => {'Content-Type' => 'application/json'}
    )
    charge = Charge.find(1)
    assert_requested(:get, 'http://example.com/v1/charges/1')
    assert_equal 1, charge.id
    assert_equal 2000, charge.amount
  end

  def test_instance_put
    stub_request(:any, 'http://example.com/v1/charges/1/capture')
    charge = Charge.new({:id => 1})
    charge.put(:capture)
    assert_requested(:put, 'http://example.com/v1/charges/1/capture')
  end

  def test_defaults
    stub_request(:any, 'http://example.com/v1/tokens/1/capture?one=1')
    charge = Token.new({:id => 1})
    charge.get(:capture)
    assert_requested(:get, 'http://example.com/v1/tokens/1/capture?one=1')
  end

  def test_absolute_uri
    uri = Token.uri(URI.parse('http://example.com/v1/token'))
    assert_equal uri.to_s, 'http://example.com/v1/token'
  end

  def test_to_json
    charge = Charge.new(:amount => 1)
    assert_equal charge.to_json, '{"amount":1}'
  end
end
