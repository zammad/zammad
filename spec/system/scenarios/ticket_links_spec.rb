# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_link_test.rb. Adding a link via the modal
#   is covered by 'ticket add link action' in spec/system/ticket/zoom/link_spec.rb;
#   this scenario keeps the remainders: the link panel of both affected tickets
#   updating live in a second session, deleting via the sidebar and the persistence
#   of both operations across reloads.
RSpec.describe 'Scenario > Ticket links', authenticated_as: :authenticate, type: :system do
  let(:group)        { Group.find_by(name: 'Users') }
  let(:agent)        { create(:agent, password: 'test', groups: [group]) }
  let(:second_agent) { create(:agent, password: 'test', groups: [group]) }
  let(:ticket1)      { create(:ticket, group:, title: 'link counterpart one') }
  let(:ticket2)      { create(:ticket, group:, title: 'link counterpart two') }

  def authenticate
    ticket1 && ticket2

    agent
  end

  it 'links and unlinks tickets with live sync into a second session and reload persistence' do
    visit "#ticket/zoom/#{ticket2.id}"

    using_session(:second_browser) do
      login(username: second_agent.login, password: 'test')

      visit "#ticket/zoom/#{ticket1.id}"
    end

    # Create the link via the sidebar modal.
    within(:active_content) do
      click '.js-add-related-ticket'
    end

    in_modal do
      fill_in 'ticket_number', with: ticket1.number

      select 'Normal', from: 'link_type'

      click '.js-submit'
    end

    expect(page).to have_css('.content.active .ticketLinks', text: ticket1.title)

    # The counterpart ticket in the second session shows the link without reload.
    using_session(:second_browser) do
      expect(page).to have_css('.content.active .ticketLinks', text: ticket2.title)
    end

    # The link survives a reload.
    page.refresh

    expect(page).to have_css('.content.active .ticketLinks', text: ticket1.title)

    # Deleting via the sidebar removes it in both sessions.
    within '.content.active .ticketLinks' do
      find('.js-delete', visible: :all).click
    end

    expect(page).to have_no_css('.content.active .ticketLinks', text: ticket1.title)

    using_session(:second_browser) do
      expect(page).to have_no_css('.content.active .ticketLinks', text: ticket2.title)
    end

    # The removal survives a reload as well.
    page.refresh

    expect(page).to have_no_css('.content.active .ticketLinks', text: ticket1.title)
  end
end
