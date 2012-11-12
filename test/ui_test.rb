ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit'
require 'rubygems'
require 'selenium-webdriver'

class ExampleTest < Test::Unit::TestCase
    attr_reader :browser

    def setup
      @browser = Selenium::WebDriver.for :chrome
    end

    def teardown
        browser.quit
    end

    def test_page_search
	browser.get "http://www.google.com"
        puts "Page title is #{browser.title}"
        assert_equal "Google", browser.title
    end
end


