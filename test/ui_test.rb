ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit'
gem 'selenium-client', ">=1.2.8"
require 'selenium/client'

class ExampleTest < Test::Unit::TestCase
    attr_reader :browser

    def setup
      browser = Selenium::WebDriver.for :firefox 
    end

    def teardown
        browser.quit
    end

    def test_page_search
	browser.navigate_to "http://www.google.com"
        assert_equal "Google", browser.title
    end
end


