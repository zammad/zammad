# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Basic > Invalid session handling', app: :mobile, authenticated_as: false, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, :groupable, group: group) }
  let(:ticket) { create(:ticket, group: group) }

  it 'clears the authenticated flag when session check fails' do
    visit '/login'

    login(
      username: agent.login,
      password: 'test',
    )

    visit "/tickets/#{ticket.id}"

    expect_current_route "/tickets/#{ticket.id}"

    delete_cookie('^_zammad.+?')

    visit "/tickets/#{ticket.id}"

    expect_current_route "/login?redirect=/tickets/#{ticket.id}"
  end
end
