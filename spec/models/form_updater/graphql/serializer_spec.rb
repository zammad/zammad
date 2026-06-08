# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Graphql::Serializer do
  describe '.serialize' do
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
      result = described_class.serialize(user, %w[firstname lastname email out_of_office])

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
        computed_fields: {
          manualfullName: ->(u) { "#{u.firstname} #{u.lastname}" }
        }
      )

      expect(result).to include('manualfullName' => 'John Doe')
    end
  end
end
