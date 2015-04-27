ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'
require 'simplecov'
require 'simplecov-rcov'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
    #
    # Note: You'll currently still have to declare fixtures explicitly in integration tests
    # -- they do not yet inherit this setting
    SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
    SimpleCov.start
    fixtures :all

    # disable transactions
    self.use_transactional_fixtures = false

    # clear cache
    Cache.clear

    # load seeds
    load "#{Rails.root}/db/seeds.rb"

    # set system mode to done / to activate
    Setting.set('system_init_done', true)

    setup do

      # clear cache
      Cache.clear

      # set current user
      puts 'reset UserInfo.current_user_id'
      UserInfo.current_user_id = nil
    end

    # Add more helper methods to be used by all tests here...
  end
end
