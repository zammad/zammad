# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::FormUpdater, authenticated_as: :agent, type: :graphql do
  let(:agent) { create(:agent) }

  context 'when fetching form updater data' do
    let(:query) do
      <<~QUERY
        query formUpdater($formUpdaterId: EnumFormUpdaterId!, $relationFields: [FormUpdaterRelationField!]!, $meta: FormUpdaterMetaInput!, $data: JSON!, $id: ID) {
          formUpdater(formUpdaterId: $formUpdaterId, relationFields: $relationFields, meta: $meta, data: $data, id: $id)
        }
      QUERY
    end
    let(:variables) { { formUpdaterId: 'FormUpdater__Updater__Ticket__Create', meta: { formId: 12_345 }, data: {}, relationFields: relation_fields } }
    let(:relation_fields) do
      [
        {
          name:     'group_id',
          relation: 'group',
        }
      ]
    end
    let(:expected) do
      {
        'group_id' => {
          options: [
            {
              label: 'Users',
              value: 1
            }
          ]
        }
      }
    end

    before do
      gql.execute(query, variables: variables)
    end

    it 'returns form updater data' do
      expect(gql.result.data).to eq(expected)
    end
  end
end
