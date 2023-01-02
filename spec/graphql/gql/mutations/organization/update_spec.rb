# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Organization::Update, type: :graphql do
  context 'when updating organizations', authenticated_as: :user do
    let(:user)               { create(:agent, preferences: { locale: 'de-de' }) }
    let(:organization)       { create(:organization) }
    let(:variables)          { { id: gql.id(organization), input: input_payload } }
    let(:input_payload)      { {} }
    let(:query) do
      <<~QUERY
        mutation organizationUpdate($id: ID!, $input: OrganizationInput!) {
          organizationUpdate(id: $id, input: $input) {
            organization {
              id
              name
              objectAttributeValues {
                attribute {
                  name
                }
                value
              }
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:custom_translations) { { "can't be blank" => 'darf nicht leer sein', 'This field %s' => 'Dieses Feld %{message}', 'This object already exists.' => 'Dieses Objekt existiert bereits.' } } # rubocop:disable Style/FormatStringToken

    before do
      allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
      gql.execute(query, variables: variables)
    end

    context 'when updating organization name with empty attributes' do
      let(:input_payload) { { name: 'NewName', objectAttributeValues: [] } }

      it 'returns updated organization name' do
        expect(gql.result.data['organization']).to include('name' => 'NewName')
      end
    end

    context 'when updating organization with empty name' do
      let(:input_payload) { { name: '' } }

      it 'returns a user error' do
        expect(gql.result.data['errors'].first).to include('field' => 'name', 'message' => 'Dieses Feld darf nicht leer sein')
      end
    end

    context 'when updating organization with name of another organization' do
      let(:input_payload) { { name: other_org.name } }
      let(:other_org)     { create(:organization) }

      it 'returns a user error' do
        expect(gql.result.data['errors'].first).to include('message' => 'Dieses Objekt existiert bereits.')
      end
    end

    context 'when updating organization name without attributes' do
      let(:input_payload) { { name: 'NewName' } }

      it 'returns updated organization name' do
        expect(gql.result.data['organization']).to include('name' => 'NewName')
      end
    end

    context 'when dealing with object attributes', db_strategy: :reset do
      let!(:object_attributes) do
        screens = { create: { 'admin.organization': { shown: true, required: false } } }
        attribute_text = create(:object_manager_attribute_text, object_name: 'Organization',
                                                                screens:     screens)
        attribute_multiselect = create(:object_manager_attribute_multiselect, object_name: 'Organization',
                                                                              screens:     screens)
        attribute_integer = create(:object_manager_attribute_integer, object_name: 'Organization',
                                                                      screens:     screens)
        attribute_boolean = create(:object_manager_attribute_boolean, object_name: 'Organization',
                                                                      screens:     screens)

        ObjectManager::Attribute.migration_execute

        {
          text:        attribute_text,
          multiselect: attribute_multiselect,
          integer:     attribute_integer,
          boolean:     attribute_boolean,
        }
      end

      let(:input_payload) do
        {
          objectAttributeValues: [
            {
              name:  object_attributes[:text].name,
              value: 'some test value',
            },
            {
              name:  object_attributes[:multiselect].name,
              value: %w[key_1 key_2],
            },
            {
              name:  object_attributes[:integer].name,
              value: 1337,
            },
            {
              name:  object_attributes[:boolean].name,
              value: true,
            },
          ]
        }
      end

      it 'returns updated organization object attributes' do
        oas = gql.result.data['organization']['objectAttributeValues']

        expect(oas.map { |oa| { oa['attribute']['name'] => oa['value'] } }).to eq(
          [
            {
              object_attributes[:text].name => 'some test value',
            },
            {
              object_attributes[:multiselect].name => %w[key_1 key_2],
            },
            {
              object_attributes[:integer].name => 1337,
            },
            {
              object_attributes[:boolean].name => true,
            },
          ]
        )
      end
    end

    context 'when trying to update without having correct permissions' do
      let(:user) { create(:customer) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
