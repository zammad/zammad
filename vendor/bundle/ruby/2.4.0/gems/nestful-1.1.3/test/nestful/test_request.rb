require 'test_helper'

class TestRequest < Minitest::Test
  def test_get
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :get).execute
    assert_requested(:get, 'http://example.com/v1/tokens')
  end

  def test_post
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :post).execute
    assert_requested(:post, 'http://example.com/v1/tokens')
  end

  def test_delete
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :delete).execute
    assert_requested(:delete, 'http://example.com/v1/tokens')
  end

  def test_put
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :put).execute
    assert_requested(:put, 'http://example.com/v1/tokens')
  end

  def test_patch
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :patch).execute
    assert_requested(:patch, 'http://example.com/v1/tokens')
  end

  def test_head
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :head).execute
    assert_requested(:head, 'http://example.com/v1/tokens')
  end

  def test_query_params
    stub_request(:any, 'http://example.com/v1/tokens?card=1')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :get, :params => {:card => 1}).execute
    assert_requested(:get, 'http://example.com/v1/tokens?card=1')
  end

  def test_form_params
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :post, :params => {:number => 4242, :exp_month => 12}).execute
    assert_requested(:post, 'http://example.com/v1/tokens', :body => 'number=4242&exp_month=12')
  end

  def test_nestled_form_params
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :post, :params => {:card => {:number => 4242, :exp_month => 12}}).execute
    assert_requested(:post, 'http://example.com/v1/tokens', :body => 'card[number]=4242&card[exp_month]=12')
  end

  def test_json_params
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :method => :post, :format => :json, :params => {:card => {:number => 4242, :exp_month => 12}}).execute
    assert_requested(:post, 'http://example.com/v1/tokens', :body => '{"card":{"number":4242,"exp_month":12}}', :headers => {'Content-Type' => 'application/json'})
  end

  def test_form_and_query_params
    stub_request(:any, 'http://example.com/v1/tokens?query=123')
    Nestful::Request.new('http://example.com/v1/tokens?query=123', :method => :post, :params => {:number => 4242, :exp_month => 12}).execute
    assert_requested(:post, 'http://example.com/v1/tokens?query=123', :body => 'number=4242&exp_month=12')
  end

  def test_timeout
    skip # TODO
  end

  def test_auth
    stub_request(:any, 'http://example.com/v1/tokens')
    Nestful::Request.new('http://example.com/v1/tokens', :auth_type => :bearer, :password => 'password1').execute
    assert_requested(:get, 'http://example.com/v1/tokens', :headers => {'Authorization' => 'Bearer password1'})
  end
end
