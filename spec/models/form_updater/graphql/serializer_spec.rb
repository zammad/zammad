# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Graphql::Serializer do
  describe '.serialize' do
    let(:current_user) { create(:agent) }
    let(:user) do
      create(:user,
             firstname:                    'John',
             lastname:                     'Doe',
             email:                        'john@example.com',
             out_of_office:                true,
             out_of_office_replacement_id: create(:agent).id,
             out_of_office_start_at:       1.day.ago,
             out_of_office_end_at:         1.day.from_now)
    end

    it 'serializes basic fields with camelCase keys' do
      result = described_class.serialize(user, %w[firstname lastname email out_of_office], current_user:)

      expect(result).to include(
        '__typename'  => 'User',
        'firstname'   => 'John',
        'lastname'    => 'Doe',
        'email'       => 'john@example.com',
        'outOfOffice' => true,
      )
    end

    it 'handles nested relations' do
      organization = create(:organization, name: 'Acme Corp')
      user.update!(organization: organization)

      result = described_class.serialize(
        user,
        %w[firstname],
        current_user:,
        relations: { organization: %w[name] }
      )

      expect(result['organization']).to include(
        '__typename' => 'Organization',
        'name'       => 'Acme Corp'
      )
    end

    it 'handles computed fields' do
      result = described_class.serialize(
        user,
        %w[firstname],
        current_user:,
        computed_fields: {
          manualfullName: ->(u) { "#{u.firstname} #{u.lastname}" }
        }
      )

      expect(result).to include('manualfullName' => 'John Doe')
    end

    context 'with a customer' do
      let(:organization) { create(:organization, domain: 'acme.example', vip: true) }
      let(:current_user) { create(:customer, organization:) }

      let(:serialized) do
        described_class.serialize(
          user,
          %w[firstname lastname email phone],
          current_user:,
          relations:       { organization: %w[name domain vip] },
          computed_fields: { hasSecondaryOrganizations: ->(u) { u.organization_ids.present? } }
        )
      end

      context 'when serializing a user outside of the own organization' do
        it 'returns nothing' do
          expect(serialized).to be_nil
        end
      end

      context 'when serializing a user of the own organization' do
        before { user.update!(organization:, phone: '+49 123') }

        it 'returns only the fields the field scope permits', :aggregate_failures do
          expect(serialized).to include('firstname' => 'John', 'lastname' => 'Doe')
          expect(serialized.keys).not_to include('email', 'phone', 'organization', 'hasSecondaryOrganizations')
        end
      end

      context 'when serializing the own account' do
        let(:user) { current_user }

        it 'checks the organization on its own', :aggregate_failures do
          expect(serialized).to include('email' => current_user.email, 'hasSecondaryOrganizations' => false)
          expect(serialized['organization']).to include('name' => organization.name)
          expect(serialized['organization'].keys).not_to include('domain', 'vip')
        end
      end
    end
  end
end
