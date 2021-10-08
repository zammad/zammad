# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance - App Version', type: :system do
  it 'check that new version modal dialog is present' do
    visit 'ticket/zoom/1'

    page.execute_script 'App.Event.trigger("maintenance", {type:"app_version", app_version:"1234:false"} )'

    expect(page).to have_no_text('new version', wait: 10)

    page.execute_script 'App.Event.trigger("maintenance", {type:"app_version", app_version:"1234:true"} )'

    modal_ready timeout: 10

    within '.modal-dialog' do
      expect(page).to have_text('new version')
    end
  end
end
