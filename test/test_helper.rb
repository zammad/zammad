ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'
require 'simplecov'
require 'simplecov-rcov'
require 'coveralls'
Coveralls.wear!

#ActiveSupport::TestCase.test_order = :sorted

class ActiveSupport::TestCase
  self.test_order = :sorted

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

  # disable transactions
  self.use_transactional_fixtures = false

  # clear cache
  Cache.clear

  # load seeds
  load "#{Rails.root}/db/seeds.rb"
  load "#{Rails.root}/test/fixtures/seeds.rb"

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

    # remove all session messages
    Sessions.cleanup

    # remove background jobs
    Delayed::Job.destroy_all
    Trigger.destroy_all
    ActivityStream.destroy_all
    PostmasterFilter.destroy_all
    Ticket.destroy_all

    # reset settings
    Setting.all.pluck(:name).each { |name|
      next if name == 'models_searchable' # skip setting
      Setting.reset(name, false)
    }
    Setting.set('system_init_done', true)
    Setting.reload

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
    file = "#{Rails.root}/log/#{Rails.env}.log"
    lines = []
    IO.foreach(file) do |line|
      lines.push line
    end
    count = 0
    lines.reverse.each { |line|
      break if line =~ /\+\+\+\+NEW\+\+\+\+TEST\+\+\+\+/
      next if line !~ /Send notification \(#{type}\)/
      next if line !~ /to:\s#{recipient}/
      count += 1
    }
    count
  end

  def email_count(recipient)

    # read config file and count & recipients
    file = "#{Rails.root}/log/#{Rails.env}.log"
    lines = []
    IO.foreach(file) do |line|
      lines.push line
    end
    count = 0
    lines.reverse.each { |line|
      break if line =~ /\+\+\+\+NEW\+\+\+\+TEST\+\+\+\+/
      next if line !~ /Send email to:/
      next if line !~ /to:\s'#{recipient}'/
      count += 1
    }
    count
  end

end
