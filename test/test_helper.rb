# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'cache'

require 'test_support_helper'

class ActiveSupport::TestCase

  ActiveRecord::Base.logger = Rails.logger.clone
  ActiveRecord::Base.logger.level = Logger::INFO

  # clear cache
  Cache.clear

  # load seeds
  load Rails.root.join('db/seeds.rb')
  load Rails.root.join('test/fixtures/seeds.rb')

  # set system mode to done / to activate
  Setting.set('system_init_done', true)

  setup do

    # exit all threads
    Thread.list.each do |thread|
      next if thread == Thread.current

      thread.exit
      thread.join
    end

    # clear cache
    Cache.clear

    # reload settings
    Setting.reload

    # remove all session messages
    Sessions.cleanup

    # set current user
    UserInfo.current_user_id = nil

    # set interface handle
    ApplicationHandleInfo.current = 'unknown'

    Rails.logger.info '++++NEW++++TEST++++'

    travel_back
  end

  teardown do
    travel_back
  end

  # Add more helper methods to be used by all tests here...
  def email_notification_count(type, recipient)

    # read config file and count type & recipients
    file = Rails.root.join('log', "#{Rails.env}.log")
    lines = []
    IO.foreach(file) do |line|
      lines.push line
    end
    count = 0
    lines.reverse_each do |line|
      break if line.include?('++++NEW++++TEST++++')
      next if !line.match?(%r{Send notification \(#{type}\)})
      next if !line.match?(%r{to:\s#{recipient}})

      count += 1
    end
    count
  end

end
