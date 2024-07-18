# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, title: 'Ticket Title', group: group) }

  # TODO: we should add a test which checks also the handling for multiple tabs
  context 'when subscribing to a ticket' do
    it 'updates the content on the page' do
      visit "/tickets/#{ticket.id}"

      wait_for_gql 'apps/mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.graphql'
      expect(page).to have_text('Ticket Title')

      wait_for_subscription_start 'ticketUpdates'

      ticket.update!(title: 'New Title')
      wait_for_subscription_update 'ticketUpdates'

      expect(page).to have_text('New Title')
    end
  end
end
