require 'test_helper'

class TestResponse < Minitest::Test
  def test_headers
    stub_request(:any, 'http://example.com/v1/charges').to_return(:headers => {'X-TEST' => 'BAR'})
    response = Nestful.get('http://example.com/v1/charges')
    assert_equal 'BAR', response.headers['X-TEST']
  end

  def test_content_type
    stub_request(:any, 'http://example.com/v1/charges').to_return(:headers => {'Content-Type' => 'application/json'})
    response = Nestful.get('http://example.com/v1/charges')
    assert_equal 'application/json', response.headers.content_type
  end

  def test_body
    stub_request(:any, 'http://example.com/v1/charges').to_return(:body => 'ok')
    response = Nestful.get('http://example.com/v1/charges')
    assert_equal 'ok', response.body
  end

  def test_parse_json
    stub_request(:any, 'http://example.com/v1/charges').to_return(:headers => {'Content-Type' => 'application/json'}, :body => '{"result":true}')
    response = Nestful.get('http://example.com/v1/charges')
    assert_equal({'result' => true}, response.decoded)
  end

  def test_status
    stub_request(:any, 'http://example.com/v1/charges').to_return(:status => 201)
    response = Nestful.get('http://example.com/v1/charges')
    assert_equal 201, response.status
  end

  def test_errors_include_request
    stub_request(:any, 'http://example.com/v1/charges').to_return(:status => 404)

    begin
      Nestful.get('http://example.com/v1/charges')
    rescue Nestful::ResourceNotFound => e
      assert_equal 'http://example.com/v1/charges', e.request.url
    end
  end

  def test_raises_404
    stub_request(:any, 'http://example.com/v1/charges').to_return(:status => 404)

    assert_raises Nestful::ResourceNotFound do
      Nestful.get('http://example.com/v1/charges')
    end
  end

  def test_raises_400
    stub_request(:any, 'http://example.com/v1/charges').to_return(:status => 400)

    assert_raises Nestful::BadRequest do
      Nestful.get('http://example.com/v1/charges')
    end
  end

  def test_delegation
    stub_request(:any, 'http://example.com/v1/charges').to_return(:headers => {'Content-Type' => 'application/json'}, :body => '{"result":true}')
    response = Nestful.get('http://example.com/v1/charges')

    assert response.respond_to?(:fetch)
    assert response.fetch('result')
  end
end
