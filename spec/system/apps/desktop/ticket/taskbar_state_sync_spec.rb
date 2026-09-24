# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Taskbar state sync between browser tabs', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, password: 'test', groups: [group]) }
  let(:ticket) { create(:ticket, group:).tap { |ticket| create(:ticket_article, ticket:) } }

  def open_ticket
    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')
  end

  def wait_for_selected_option(label, option)
    wait.until { find_select(label).has_css?('[role="listitem"]', exact_text: option, wait: false) }
  end

  def subscription_update_received?(number)
    page.evaluate_script("window.testFlags.get('__gql subscription userCurrentTaskbarItemStateUpdates #{number}', true)")
  end

  it 'applies the changes of the other tab without echoing the own ones back' do
    open_ticket

    using_session(:other_tab) do
      login(username: agent.login, password: 'test')
      open_ticket
    end

    find_select('Priority').select_option('3 high')

    using_session(:other_tab) do
      wait_for_selected_option('Priority', '3 high')

      find_select('State').select_option('closed')
    end

    wait_for_selected_option('State', 'closed')

    # Delivered in order, so an echo of the own change would have been the first update.
    expect(subscription_update_received?(1)).to be(true)
    expect(subscription_update_received?(2)).to be_falsey
  end
end
