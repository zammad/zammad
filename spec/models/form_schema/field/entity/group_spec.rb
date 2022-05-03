# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormSchema::Field::Entity::Group) do
  subject(:schema) { described_class.new(context: context, **base_attributes, **attributes).schema }

  context 'when generating schema information' do
    let(:type) { 'select' }
    let(:base_attributes) do
      {
        name:  'my_field',
        label: 'Label',
        value: 'initial content',
      }
    end
    let(:attributes) do
      { placeholder: 'nice placeholder', }
    end
    let(:expected_attributes) do
      attributes.merge({ options: [ { value: 1, label: 'Users' } ] })
    end

    before do
      Group.where.not(id: 1).delete_all
    end

    context 'when in non-graphql context' do
      let(:context) { Struct.new(:current_user, :current_user?) }

      it 'returns fields' do
        expect(schema).to eq(base_attributes.merge(type: type).merge({ props: expected_attributes }))
      end
    end

    context 'when in graphql context' do
      let(:context) { Gql::Context::CurrentUserAware.new(query: {}, schema: Gql::ZammadSchema, values: {}, object: {}) }

      it 'returns fields' do
        expected_attributes[:options].each do |option|
          option[:value] = Gql::ZammadSchema.id_from_object(Group.find(option[:value]))
        end
        expect(schema).to eq(base_attributes.merge(type: type).merge({ props: expected_attributes }))
      end
    end
  end
end
