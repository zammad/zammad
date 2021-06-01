# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AutoWizardBrowserTest < TestCase
  def test_auto_wizard
    @browser = browser_instance
    location(url: browser_url)

    watch_for(
      css:     'body',
      value:   'auto wizard is enabled',
      timeout: 10,
    )

    location(url: "#{browser_url}/#getting_started/auto_wizard")

    watch_for(
      css:     'body',
      value:   'auto wizard is enabled',
      timeout: 10,
    )

    location(url: "#{browser_url}/#getting_started/auto_wizard/secret_token")

    watch_for(
      css:       '.user-menu .user a',
      attribute: 'title',
      value:     'hans.atila@zammad.org',
      timeout:   20,
    )

    clues_close

    # wait unless elasticsearch has index all objects from auto wizard
    sleep 10

    organization_open_by_search(
      value: 'Demo Organization',
    )
    watch_for(
      css:   '.active .profile-window',
      value: 'Demo Organization',
    )
    watch_for(
      css:   '.active .profile-window',
      value: 'Atila',
    )

    logout

    login(
      username: 'hans.atila@zammad.org',
      password: 'Z4mm4dr0ckZ!',
    )
    watch_for(
      css:       '.user-menu .user a',
      attribute: 'title',
      value:     'hans.atila@zammad.org',
      timeout:   8,
    )
  end

end
