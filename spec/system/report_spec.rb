# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Report', type: :system, searchindex: true do
  before do
    configure_elasticsearch(required: true, rebuild: true)
  end

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
end
