# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  end
end
