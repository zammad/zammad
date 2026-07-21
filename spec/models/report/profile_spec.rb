# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe Report::Profile, type: :model do
  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'
  describe '.sorted' do
    before { described_class.destroy_all }

    let!(:profile_z) { create(:report_profile, name: 'zzz') }
    let!(:profile_a) { create(:report_profile, name: 'aaa') }
    let!(:profile_b) { create(:report_profile, name: 'bbb') }

    it 'returns profiles ordered by name' do
      expect(described_class.sorted).to eq([profile_a, profile_b, profile_z])
    end
  end

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
