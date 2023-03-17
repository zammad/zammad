# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
end
