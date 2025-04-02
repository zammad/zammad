# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Report::Profile, type: :model do
  describe 'Organization is removed in the report profile after an reload of the browser tab #5469' do
    let(:conditions_orgs) { create_list(:organization, 3) }
    let(:report_profile)  { create(:report_profile, condition: condition) }
    let(:condition) do
      {
        'ticket.organization_id' => {
          'operator'         => 'is',
          'pre_condition'    => 'specific',
          'value'            => conditions_orgs.map { |row| row.id.to_s },
          'value_completion' => ''
        }
      }
    end

    it 'does contain assets for the conditions' do
      expect(report_profile.assets({})[:Organization].keys.sort).to eq(conditions_orgs.map(&:id).sort)
    end
  end
end
