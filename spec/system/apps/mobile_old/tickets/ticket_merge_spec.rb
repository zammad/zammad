# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Merge tickets', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)          { create(:group) }
  let(:agent)          { create(:agent, groups: [group]) }
  let!(:source_ticket) { create(:ticket, title: 'Source', group: group) }
  let!(:target_ticket) { create(:ticket, title: 'Target', group: group) }

  before do
    searchindex_model_reload([Ticket])
  end

  context 'when merging tickets', searchindex: true do
    it 'can merge two tickets' do
      visit "/tickets/#{source_ticket.id}"
      wait_for_form_to_settle('form-ticket-edit')
      find_button('Show ticket actions').click
      find_button('Merge tickets').click
      search_input = find('[role="searchbox"]')
      search_input.fill_in(with: target_ticket.title)

      find('[role="option"]', text: "#{Setting.get('ticket_hook')}#{Setting.get('ticket_hook_divider')}#{target_ticket.number} - #{target_ticket.title}").click

      wait_for_gql 'shared/entities/ticket/graphql/queries/autocompleteSearchTicket.graphql'

      find('[aria-label="Confirm merge"]').click
      find_button('OK').click

      wait_for_gql 'shared/entities/ticket/graphql/mutations/merge.graphql'

      expect_current_route "/tickets/#{target_ticket.id}"

      expect(page).to have_no_css('[role="dialog"]')
    end
  end
end
