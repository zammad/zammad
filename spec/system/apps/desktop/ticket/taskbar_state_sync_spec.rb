# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Taskbar state sync between browser tabs', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:).tap { |ticket| create(:ticket_article, ticket:) } }

  def open_ticket
    open_desktop_ticket(ticket)
    wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')
  end

  def subscription_update_received?(number)
    test_flag_set?("__gql subscription userCurrentTaskbarItemStateUpdates #{number}")
  end

  it 'applies the changes of the other tab without echoing the own ones back' do
    open_ticket

    other_tab = open_tab
    on_tab(other_tab) { open_ticket }

    select_option('Priority', '3 high')

    on_tab(other_tab) do
      expect(selected_options('Priority')).to have_text('3 high')

      select_option('State', 'closed')
    end

    expect(selected_options('State')).to have_text('closed')

    # Delivered in order, so an echo of the own change would have been the first update.
    expect(subscription_update_received?(1)).to be(true)
    expect(subscription_update_received?(2)).to be_falsey
  end
end
