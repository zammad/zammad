ENV['RAILS_ENV'] = 'test'
# rubocop:disable ClassAndModuleChildren
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'

class ActiveSupport::TestCase
  # disable transactions
  #self.use_transactional_fixtures = false

  # clear cache
  Cache.clear

  # load seeds
  load "#{Rails.root}/db/seeds.rb"

  setup do

    # clear cache
    Cache.clear

    # set current user
    puts 'reset UserInfo.current_user_id'
    UserInfo.current_user_id = nil
  end

  # Add more helper methods to be used by all tests here...
end
