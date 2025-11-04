# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Shortcuts', type: :system do
  describe 'Shortcuts in Zoom', authenticated_as: :agent do
    let(:agent)   { create(:agent, groups: [Group.find_by(name: 'Users')]) }
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), state: Ticket::State.find_by(name: 'new')) }

    context 'when close with shift + c' do
      it 'do change state to pending reminder without saving and closed it with shift + c' do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          select('pending reminder', from: 'state_id')
          expect(page).to have_css("div[data-name='pending_time']")
        end

        within('.sidebar-header') do
          click('.js-headline')
          click('.js-headline')

          send_keys([:shift, 'c'])
        end

        within(:active_content) do
          expect(page).to have_select('state_id', selected: 'closed')
          expect(page).to have_no_text('Discard your unsaved changes')
          expect(ticket.reload.state.name).to eq('closed')
        end
      end
    end
  end
end
