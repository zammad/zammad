# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance - App Version', type: :system do
  it 'check that new version modal dialog is present' do
    visit 'ticket/zoom/1'

    AppVersion.trigger_browser_reload(AppVersion::MSG_APP_VERSION)

    in_modal timeout: 30 do
      expect(page).to have_text('new version')
    end
  end
end
