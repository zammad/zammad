# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > CTI (generic)', type: :system do
  let!(:agent)    { create(:agent) }
  let!(:customer) { create(:customer) }

  it 'offers only users with the cti.agent permission in the caller log filter' do
    # The picker lists the users the client has loaded; the user management loads
    #   them, and the in-app navigation keeps them.
    # normalize_ws avoids driver differences in how whitespace between adjacent table cells is rendered
    visit 'manage/users'
    expect(page).to have_text(agent.fullname, normalize_ws: true).and have_text(customer.fullname, normalize_ws: true)

    visit 'system/integration/cti'
    check 'setting-switch', allow_label_click: true

    # Switching the integration on re-renders the page, so no node is held across it.
    picker = '.js-notifyMap .js-userSelectorBlank .js-pool .js-option'

    expect(page).to have_css(picker, text: agent.fullname)
    expect(page).to have_no_css(picker, text: customer.fullname)
  end
end
