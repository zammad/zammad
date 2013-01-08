ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'simplecov'
require 'simplecov-rcov'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
  fixtures :all

  # disable transactions
  self.use_transactional_fixtures = false

  # load seeds
  load "#{Rails.root}/db/seeds.rb" 

  # Add more helper methods to be used by all tests here...
end
