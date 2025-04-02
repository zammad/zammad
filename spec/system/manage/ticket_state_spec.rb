# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Ticket States', type: :system do
  describe 'create new state' do
    let(:new_state_name) { Faker::Lorem.unique.word.capitalize }

    before do
      visit 'manage/ticket_states'
      click_on 'New Ticket State'
    end

    it 'creates a new state' do
      fill_in 'Name', with: new_state_name
      find('[name=state_type_id]').select('pending reminder')

      scroll_into_view('button.js-submit', position: :bottom)
      click_on 'Submit'

      within :active_content do
        expect(find("tr[data-id='#{Ticket::State.last.id}']")).to have_text(new_state_name)
      end
    end

    it 'does not allow to select merged type' do
      expect(page).to have_no_css('option', text: 'merged')
    end
  end

  describe 'managing existing states' do
    let(:state) { Ticket::State.find_by name: state_name }
    let(:state_row) { find("tr[data-id='#{state.id}']") }

    before do
      visit 'manage/ticket_states'
    end

    context 'when state is merged' do
      let(:state_name) { 'merged' }

      it 'does not open edit dialog' do
        state_row.click

        expect(page).to have_no_text('Edit:')
      end

      it 'has no additional actions' do
        expect(state_row).to have_no_css('[data-table-action]', visible: :all)
      end
    end

    context 'when state is non-merged' do
      let(:state_name) { 'pending close' }

      it 'allows to edit the state' do
        new_state_name = Faker::Lorem.unique.word

        state_row.click

        in_modal do
          fill_in 'Name', with: new_state_name
          click_on 'Submit'
        end

        expect(page).to have_text new_state_name
      end

      it 'has additional actions' do
        expect(state_row).to have_css('[data-table-action]', count: 3, visible: :all)
      end
    end
  end
end
