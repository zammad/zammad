# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'test_support_helper'

class ActiveSupport::TestCase

  # disable transactions / to work with own database connections for each thread
  self.use_transactional_tests = false

  ActiveRecord::Base.logger = Rails.logger.clone
  ActiveRecord::Base.logger.level = Logger::INFO

  # clear cache
  Rails.cache.clear

  # load seeds
  load Rails.root.join('db/seeds.rb')
  load Rails.root.join('test/fixtures/seeds.rb')

  # set system mode to done / to activate
  Setting.set('system_init_done', true)

  setup do

    # clear cache
    Rails.cache.clear

    # reload settings
    Setting.reload

    # remove all session messages
    Sessions.cleanup

    # remove old delayed jobs
    Delayed::Job.destroy_all

    # set current user
    UserInfo.current_user_id = nil

    travel_back
  end

  # Add more helper methods to be used by all tests here...
end
