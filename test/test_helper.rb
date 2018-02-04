ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'
require 'simplecov'
require 'simplecov-rcov'
require 'coveralls'
Coveralls.wear!

class ActiveSupport::TestCase

  ActiveRecord::Base.logger = Rails.logger.clone
  ActiveRecord::Base.logger.level = Logger::INFO

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                   SimpleCov::Formatter::RcovFormatter,
                                                                   Coveralls::SimpleCov::Formatter
                                                                 ])
  merge_timeout = 3600
  SimpleCov.start
  fixtures :all

  # clear cache
  Cache.clear

  # load seeds
  load Rails.root.join('db', 'seeds.rb')
  load Rails.root.join('test', 'fixtures', 'seeds.rb')

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

  # Add more helper methods to be used by all tests here...
  def email_notification_count(type, recipient)

    # read config file and count type & recipients
    file = Rails.root.join('log', "#{Rails.env}.log")
    lines = []
    IO.foreach(file) do |line|
      lines.push line
    end
    count = 0
    lines.reverse.each do |line|
      break if line.match?(/\+\+\+\+NEW\+\+\+\+TEST\+\+\+\+/)
      next if line !~ /Send notification \(#{type}\)/
      next if line !~ /to:\s#{recipient}/
      count += 1
    end
    count
  end

  def email_count(recipient)

    # read config file and count & recipients
    file = Rails.root.join('log', "#{Rails.env}.log")
    lines = []
    IO.foreach(file) do |line|
      lines.push line
    end
    count = 0
    lines.reverse.each do |line|
      break if line.match?(/\+\+\+\+NEW\+\+\+\+TEST\+\+\+\+/)
      next if line !~ /Send email to:/
      next if line !~ /to:\s'#{recipient}'/
      count += 1
    end
    count
  end

end
