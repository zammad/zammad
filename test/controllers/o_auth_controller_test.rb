
require 'test_helper'

class OAuthControllerTest < ActionDispatch::IntegrationTest

  test 'o365 - start' do
    get '/auth/microsoft_office365', params: {}
    assert_response(302)
    assert_match('https://login.microsoftonline.com/common/oauth2/v2.0/authorize', @response.body)
    assert_match('redirect_uri=http%3A%2F%2Fzammad.example.com%2Fauth%2Fmicrosoft_office365%2Fcallback', @response.body)
    assert_match('scope=openid+email+profile', @response.body)
    assert_match('response_type=code', @response.body)
  end

  test 'o365 - callback' do
    get '/auth/microsoft_office365/callback?code=1234&state=1234', params: {}
    assert_response(302)
    assert_match('302 Moved', @response.body)
  end

  test 'auth failure' do
    get '/auth/failure?message=123&strategy=some_provider', params: {}
    assert_response(422)
    assert_match('<title>422: Unprocessable Entity</title>', @response.body)
    assert_match('<h1>422: The change you wanted was rejected.</h1>', @response.body)
    assert_match('<div>Message from some_provider: 123</div>', @response.body)
  end

end
