# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::ApplyValue::OrganizationAutocomplete do
  describe '.resolve_option' do
    subject(:option) { described_class.resolve_option(organization.id, current_user:) }

    let(:organization) { create(:organization, domain: 'acme.example', vip: true) }

    context 'with an agent' do
      let(:current_user) { create(:agent) }

      it 'resolves the organization with all fields' do
        expect(option).to include(
          value:        organization.id,
          label:        organization.name,
          organization: include('domain' => 'acme.example', 'vip' => true),
        )
      end
    end

    context 'with a customer' do
      let(:current_user) { create(:customer) }

      it 'resolves no other organization' do
        expect(option).to be_nil
      end

      context 'when resolving the own organization' do
        let(:current_user) { create(:customer, organization:) }

        it 'resolves it within the field scope', :aggregate_failures do
          expect(option).to include(value: organization.id, label: organization.name)
          expect(option[:organization].keys).not_to include('domain', 'vip')
        end
      end
    end
  end
end
