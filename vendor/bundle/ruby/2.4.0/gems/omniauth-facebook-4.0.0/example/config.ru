require 'bundler/setup'
require 'omniauth-facebook'
require './app.rb'

use Rack::Session::Cookie, secret: 'abc123'

use OmniAuth::Builder do
  provider :facebook, ENV['APP_ID'], ENV['APP_SECRET']
end

run Sinatra::Application
