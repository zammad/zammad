# encoding: utf-8
require 'browser_test_helper'

class AutoWizardTest < TestCase
  def test_auto_wizard
    @browser = browser_instance
    location( url: browser_url )

    watch_for(
      css: 'body',
      value: 'Invite',
      timeout: 10,
    )

    click( css: '.content .btn--primary' )

    watch_for(
      css: '.user-menu .user a',
      attribute: 'title',
      value: 'hans.atila@zammad.org',
      timeout: 20,
    )

    organization_open_by_search(
      value: 'Demo Organization',
    )
    watch_for(
      css: '.active .profile-window',
      value: 'Demo Organization',
    )
    watch_for(
      css: '.active .profile-window',
      value: 'Atila',
    )

  end

end
