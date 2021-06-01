# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

return if !ENV['TRAVIS_CI']

require 'simplecov'
require 'simplecov-rcov'
require 'coveralls'

Coveralls.wear!

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                   SimpleCov::Formatter::RcovFormatter,
                                                                   Coveralls::SimpleCov::Formatter
                                                                 ])
  SimpleCov.start
  fixtures :all
end
