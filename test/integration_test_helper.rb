ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'

class ActiveSupport::TestCase

  # disable transactions / to work with own database connections for each thread
  self.use_transactional_tests = false

  ActiveRecord::Base.logger = Rails.logger.clone
  ActiveRecord::Base.logger.level = Logger::INFO

  # clear cache
  Cache.clear

  # load seeds
  load "#{Rails.root}/db/seeds.rb"
  load "#{Rails.root}/test/fixtures/seeds.rb"

  setup do

    # clear cache
    Cache.clear

    # reload settings
    Setting.reload

    # remove all session messages
    Sessions.cleanup

    # set current user
    UserInfo.current_user_id = nil
  end

  # Add more helper methods to be used by all tests here...
end
