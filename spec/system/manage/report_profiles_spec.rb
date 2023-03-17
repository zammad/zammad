# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Report Profiles', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :report_profile, klass: Report::Profile, path: 'manage/report_profiles'
  end

  context 'for reporting profiles' do
    before do
      Report::Profile.destroy_all
      visit '#manage/report_profiles'

      within :active_content do
        click 'a[data-type=new]'

        in_modal do
          fill_in 'name', with: name
          select profile_active, from: 'active'
          select 'open', from: 'condition::ticket.state_id::value'

          click_button
        end
      end
    end

    context 'when creating an inactive profile' do
      let(:name)           { 'inactive profile' }
      let(:profile_active) { 'inactive' }

      it 'creates an inactive profile report' do
        within :active_content do
          within '.page-content' do
            expect(page).to have_selector('tr.item.is-inactive')
              .and have_text(name)
          end
        end
      end
    end

    context 'when creating an active profile' do
      let(:name) { 'active profile' }
      let(:profile_active) { 'active' }

      it 'creates an active profile report on the ui' do
        within :active_content do
          within '.page-content' do
            expect(page).to have_no_selector('tr.item.is-inactive')
              .and have_text(name)
          end
        end
      end

      it 'creates an active profile report in the backend' do
        expect(Report::Profile.count).to be(1)
      end
    end
  end
end
