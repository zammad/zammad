# encoding: utf-8
require 'test_helper'

class BasicControllerTest < ActionDispatch::IntegrationTest

  test 'json requests' do

    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # 404
    get '/not_existing_url', {}, @headers
    assert_response(404)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'No route matches [GET] /not_existing_url')

    # 401
    get '/api/v1/organizations', {}, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'authentication failed')

    # 422
    get '/tests/unprocessable_entity', {}, @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'some error message')

    # 401
    get '/tests/not_authorized', {}, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'some error message')

    # 401
    get '/tests/ar_not_found', {}, @headers
    assert_response(404)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'some error message')

    # 500
    get '/tests/standard_error', {}, @headers
    assert_response(500)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'some error message')

    # 422
    get '/tests/argument_error', {}, @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'some error message')

  end

  test 'html requests' do

    # 404
    get '/not_existing_url', {}, @headers
    assert_response(404)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>404: Not Found</title>}, @response.body)
    assert_match(%r{<h1>404: Requested Ressource was not found.</h1>}, @response.body)
    assert_match(%r{No route matches \[GET\] /not_existing_url}, @response.body)

    # 401
    get '/api/v1/organizations', {}, @headers
    assert_response(401)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>401: Unauthorized</title>}, @response.body)
    assert_match(%r{<h1>401: Unauthorized</h1>}, @response.body)
    assert_match(/authentication failed/, @response.body)

    # 422
    get '/tests/unprocessable_entity', {}, @headers
    assert_response(422)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>422: Unprocessable Entity</title>}, @response.body)
    assert_match(%r{<h1>422: The change you wanted was rejected.</h1>}, @response.body)
    assert_match(/some error message/, @response.body)

    # 401
    get '/tests/not_authorized', {}, @headers
    assert_response(401)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>401: Unauthorized</title>}, @response.body)
    assert_match(%r{<h1>401: Unauthorized</h1>}, @response.body)
    assert_match(/some error message/, @response.body)

    # 401
    get '/tests/ar_not_found', {}, @headers
    assert_response(404)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>404: Not Found</title>}, @response.body)
    assert_match(%r{<h1>404: Requested Ressource was not found.</h1>}, @response.body)
    assert_match(/some error message/, @response.body)

    # 500
    get '/tests/standard_error', {}, @headers
    assert_response(500)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>500: Something went wrong</title>}, @response.body)
    assert_match(%r{<h1>500: We're sorry, but something went wrong.</h1>}, @response.body)
    assert_match(/some error message/, @response.body)

    # 422
    get '/tests/argument_error', {}, @headers
    assert_response(422)
    assert_match(/<html/, @response.body)
    assert_match(%r{<title>422: Unprocessable Entity</title>}, @response.body)
    assert_match(%r{<h1>422: The change you wanted was rejected.</h1>}, @response.body)
    assert_match(/some error message/, @response.body)

  end

end
