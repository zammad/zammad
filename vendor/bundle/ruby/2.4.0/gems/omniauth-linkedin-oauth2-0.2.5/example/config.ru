# Sample app for LinkedIn OAuth2 Strategy
# Make sure to setup the ENV variables LINKEDIN_KEY and LINKEDIN_SECRET
# Run with "bundle exec rackup"

require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-linkedin-oauth2'

class App < Sinatra::Base
  get '/' do
    redirect '/auth/linkedin'
  end

  get '/auth/:provider/callback' do
    content_type 'application/json'
    MultiJson.encode(request.env['omniauth.auth'])
  end

  get '/auth/failure' do
    content_type 'application/json'
    MultiJson.encode(request.env)
  end
end

use Rack::Session::Cookie, :secret => 'change_me'

use OmniAuth::Builder do
  provider :linkedin, ENV['LINKEDIN_KEY'], ENV['LINKEDIN_SECRET']
end

run App.new
