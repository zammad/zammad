ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit'
gem 'selenium-client', ">=1.2.8"
require 'selenium/client'

class ExampleTest < Test::Unit::TestCase
    attr_reader :browser

    def setup
      @browser = Selenium::Client::Driver.new \
          :host => "localhost",
          :port => 4444,
          :browser => "*firefox",
          :url => "http://kaldung.com",
          :timeout_in_seconds => 60
      browser.start_new_browser_session
    end

    def teardown
        browser.close_current_browser_session
    end

    def test_page_search
        browser.open "/"
        assert_equal "Google", browser.title
    end
end


