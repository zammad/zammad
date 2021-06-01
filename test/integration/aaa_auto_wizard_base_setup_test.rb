# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AaaAutoWizardBaseSetupTest < TestCase

  def test_auto_wizard
    @browser = browser_instance
    location(url: "#{browser_url}/#getting_started/auto_wizard")
    watch_for(
      css:       '.user-menu .user a',
      attribute: 'title',
      value:     'master@example.com',
      timeout:   14,
    )
  end

end
