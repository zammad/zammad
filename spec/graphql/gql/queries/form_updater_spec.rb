# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::FormUpdater, authenticated_as: :agent, type: :graphql do
  let(:agent) { create(:agent) }

  context 'when fetching form updater data' do
    let(:query) do
      <<~QUERY
        query formUpdater($formUpdaterId: EnumFormUpdaterId!, $relationFields: [FormUpdaterRelationField!]!, $meta: FormUpdaterMetaInput!, $data: JSON!, $id: ID) {
          formUpdater(formUpdaterId: $formUpdaterId, relationFields: $relationFields, meta: $meta, data: $data, id: $id) {
            fields
            flags
          }
        }
      QUERY
    end
    let(:variables) { { formUpdaterId: 'FormUpdater__Updater__Ticket__Create', meta: { formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' }, data: {}, relationFields: relation_fields } }
    let(:relation_fields) do
      [
        {
          name:     'state_id',
          relation: 'TicketState',
        }
      ]
    end
    let(:expected) do
      {
        'fields' => include({
                              'state_id' => {
                                options:                 Ticket::State.by_category(:viewable_agent_new).reorder(name: :asc).map { |state| { value: state.id, label: state.name } },
                                rejectNonExistentValues: true,
                                clearable:               true,
                                disabled:                false,
                                hidden:                  false,
                                required:                true,
                                show:                    true,
                              },
                              'title'    => {
                                disabled: false,
                                hidden:   false,
                                required: true,
                                show:     true,
                              }
                            }),
        'flags'  => {}
      }
    end

    before do
      gql.execute(query, variables: variables)
    end

    it 'returns form updater data' do
      expect(gql.result.data).to include(expected)
    end
  end
end
