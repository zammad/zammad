# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Report', searchindex: true, type: :system do
  context 'with ticket search result' do
    let(:label) { find('.content ul.checkbox-list') }

    before do
      create(:report_profile, name: report_profile_name, active: active)
      visit 'report'
    end

    context 'with an active report profile' do
      let(:report_profile_name) { 'active report profile' }
      let(:active) { true }

      it 'shows active report profile' do
        expect(label).to have_text(report_profile_name)
      end
    end

    context 'with an inactive report profile' do
      let(:report_profile_name) { 'inactive report profile' }
      let(:active) { false }

      it 'does not show inactive report profile' do
        expect(label).to have_no_text(report_profile_name)
      end
    end
  end

  context 'report profiles are displayed' do
    let!(:report_profile_active)   { create(:report_profile) }
    let!(:report_profile_inactive) { create(:report_profile, active: false) }

    it 'shows report profiles' do
      visit 'report'

      expect(page)
        .to have_css('ul.checkbox-list .label-text', text: report_profile_active.name)
        .and have_no_css('ul.checkbox-list .label-text', text: report_profile_inactive.name)
    end
  end

  context 'report profiles sorting #6146' do
    before { Report::Profile.destroy_all }

    let!(:profile_z) { create(:report_profile, name: 'zzz') }
    let!(:profile_a) { create(:report_profile, name: 'aaa') }
    let!(:profile_b) { create(:report_profile, name: 'bbb') }

    it 'shows report profiles in alphabetical order' do
      visit 'report'

      labels = all('ul.checkbox-list .label-text').map(&:text)
      expect(labels).to eq([profile_a.name, profile_b.name, profile_z.name])
    end
  end

  context 'with report profiles with date-based conditions' do
    let(:report_profile) { create(:report_profile, :condition_created_at, ticket_created_at: 1.year.ago) }

    before do
      freeze_time
      report_profile
      visit 'report'
    end

    it 'shows previous year for a profile with matching conditions' do
      click '.js-timePickerYear', text: Time.zone.now.year - 1
      click '.label-text', text: report_profile.name

      expect(page).to have_no_css('.modal')
    end
  end

  describe 'delete reporting profile with id=1 #5463' do
    context 'when report profiles are not present', authenticated_as: :authenticate do
      def authenticate
        Report::Profile.destroy_all
        true
      end

      it 'does show a message that no report profiles are given' do
        visit 'report'
        expect(page).to have_text('There are currently no report profiles configured.')
      end
    end

    context 'when selected report profile is replaced with a new one' do
      it 'does clear the session storage cache and selects the new report profile' do
        visit 'report'
        expect(page).to have_text(Report::Profile.first.name)
        click ".js-dataDownloadBackendSelector[data-backend='count::closed']"
        Report::Profile.first.destroy
        new_report_profile = create(:report_profile)
        refresh
        expect(page).to have_text(new_report_profile.name)
        expect(page).to have_no_text('The report could not be generated')
      end
    end
  end
end
