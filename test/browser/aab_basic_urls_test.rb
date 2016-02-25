# encoding: utf-8
require 'browser_test_helper'

class AABBasicUrlsTest < TestCase

  def test_logout
    @browser = browser_instance
    location(
      url: "#{browser_url}/#logout",
    )
    location_check(
      url: "#{browser_url}/#login",
    )
  end

  def test_session
    @browser = browser_instance
    location(
      url: "#{browser_url}/#system/sessions",
    )
    location_check(
      url: "#{browser_url}/#login",
    )
  end

  def test_profile
    @browser = browser_instance
    location(
      url: "#{browser_url}/#profile/linked",
    )
    location_check(
      url: "#{browser_url}/#login",
    )
  end

end
