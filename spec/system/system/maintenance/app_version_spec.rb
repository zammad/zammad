# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance - App Version', type: :system do
  it 'check that new version modal dialog is present' do
    visit 'ticket/zoom/1'

    AppVersion.set(false, 'app_version')
    AppVersion.set(true,  'app_version')

    in_modal timeout: 30 do
      expect(page).to have_text('new version')
    end
  end
end
