# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Output::Record, :aggregate_failures do
  let(:agent)        { create(:agent) }
  let(:organization) { create(:organization, name: 'Example Corp') }
  let(:customer)     { create(:customer, organization:) }

  describe '.summary', db_strategy: :reset do
    before do
      create(:object_manager_attribute_select, object_name: 'User', name: 'tier', display: 'Tier', data_option_options: { 'gold' => 'Gold partner', 'silver' => 'Silver partner' })
      create(:object_manager_attribute_textarea, object_name: 'Organization', name: 'contract_terms', display: 'Contract terms')
      create(:object_manager_attribute_text, object_name: 'User', name: 'billing_code', display: 'Billing code', additional_data_options: { permission: ['admin.user'] })
      ObjectManager::Attribute.migration_execute
    end

    def summary(record, source:, concise: false)
      described_class.summary(record.reload, user: agent, source:, concise:)
    end

    it 'gives the VIP flag, the fields by their labels and the note, marked as the record' do
      customer.update!(vip: true, tier: 'gold', department: 'Finance', note: '<p>Prefers phone calls.</p>')

      result = summary(customer, source: 'customer_record')

      expect(result.content).to eq(vip: true, fields: { 'tier' => 'Gold partner', 'department' => 'Finance' }, note: 'Prefers phone calls.')
      expect(result.facts).to eq(['VIP', 'tier: Gold partner'])
      expect(result.text).to eq(<<~TEXT.chomp)
        <text source="customer_record" field="note">
        │ Prefers phone calls.
        </text>

        <text source="customer_record" field="department">
        │ Finance
        </text>
      TEXT
    end

    it 'names only the facts a record has, nothing for a note alone' do
      customer.update!(tier: 'silver', note: 'Prefers phone calls.')

      expect(summary(customer, source: 'customer_record').facts).to eq(['tier: Silver partner'])

      customer.update!(tier: nil)

      expect(summary(customer, source: 'customer_record').facts).to be_empty
    end

    it 'leaves a field out that the user may not see, as GraphQL does' do
      customer.update!(billing_code: 'B-17', department: 'Finance')

      expect(summary(customer, source: 'customer_record').content[:fields]).to eq('department' => 'Finance')
    end

    it 'leaves the free-text fields out of the concise layer, and keeps the note' do
      organization.update!(contract_terms: 'Premium support until 2027-03.', note: 'Contract questions go to Anna Lead.')

      full    = summary(organization, source: 'organization')
      concise = summary(organization, source: 'organization', concise: true)

      expect(full.text).to include('<text source="organization" field="contract_terms">')
      expect(concise.content).to eq(note: 'Contract questions go to Anna Lead.')
      expect(concise.text).not_to include('contract_terms')
    end

    it 'cuts a long note and says how much of it is shown' do
      organization.update!(note: "#{'word ' * 300}end")

      result = summary(organization, source: 'organization')

      expect(result.content).to include(note_truncated: true)
      expect(result.content[:note].length).to be <= described_class::NOTE_LENGTH
      expect(result.text).to match(%r{\A<text source="organization" field="note" cut="[\d,]+ of 1,503 characters shown">})
    end

    it 'gives nothing for a record that holds nothing of this' do
      expect(summary(organization, source: 'organization')).to be_nil
    end
  end
end
