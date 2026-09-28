# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > CTI (generic)', type: :system do
  let!(:agent)    { create(:agent, firstname: 'Phone', lastname: 'Agent') }
  let!(:customer) { create(:customer, firstname: 'Phone', lastname: 'Customer') }

  it 'offers only users with the cti.agent permission in the caller log filter' do
    # The picker lists the users the client has loaded; the user management loads
    #   them, and the in-app navigation keeps them.
    visit 'manage/users'
    expect(page).to have_text(agent.fullname).and have_text(customer.fullname)

    visit 'system/integration/cti'
    check 'setting-switch', allow_label_click: true

    # Switching the integration on re-renders the page, so no node is held across it.
    picker = '.js-notifyMap .js-userSelectorBlank .js-pool .js-option'

    expect(page).to have_css(picker, text: agent.fullname)
    expect(page).to have_no_css(picker, text: customer.fullname)
  end
end
