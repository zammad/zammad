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

    def test_first_page
        browser.get "http://portal.znuny.com/"
	assert_equal browser.current_url, "https://portal.znuny.com/#login"
    end

    def test_login_failed
       browser.get "http://portal.znuny.com/"
       element_username = browser.find_element :name => "username"
       element_username.send_keys "roy@kaldung.de"
       element_password = browser.find_element :name => "password"
       element_password.send_keys "123456"
       element_password.submit
       assert_equal browser.current_url, "https://portal.znuny.com/#login"
    end

    def test_login_passed
       browser.get "http://portal.znuny.com/"
       element_username = browser.find_element :name => "username"
       element_username.send_keys "roy@kaldung.com"
       element_password = browser.find_element :name => "password"
       element_password.send_keys "090504"
       element_password.submit
       browser.wait_for_page_to_load
       assert_equal browser.current_url, "https://portal.znuny.com/#ticket_view/my_tickets"
    end
end


