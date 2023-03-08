# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'
require 'models/form_updater/concerns/has_security_options_examples'

RSpec.describe(FormUpdater::Updater::Ticket::Create) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:group)   { create(:group) }
  let(:user)    { create(:agent, groups: [group]) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: 12_345 } }
  let(:data)    { {} }

  let(:relation_fields) do
    [
      {
        name:     'group_id',
        relation: 'group',
      },
      {
        name:     'state_id',
        relation: 'TicketState',
      },
      {
        name:     'priority_id',
        relation: 'TicketPriority',
      },
    ]
  end

  let(:expected_result) do
    {
      'group_id'    => {
        options: [ { value: group.id, label: group.name } ],
      },
      'state_id'    => {
        options: Ticket::State.by_category(:viewable_agent_new).reorder(name: :asc).map { |state| { value: state.id, label: state.name } },
      },
      'priority_id' => {
        options: Ticket::Priority.where(active: true).reorder(id: :asc).map { |priority| { value: priority.id, label: priority.name } },
      },
    }
  end

  context 'when resolving' do
    it 'returns all resolved relation fields with correct value + label' do
      expect(resolved_result.resolve).to include(
        'group_id'    => include(expected_result['group_id']),
        'state_id'    => include(expected_result['state_id']),
        'priority_id' => include(expected_result['priority_id']),
      )
    end

    it 'returns group_id as integer' do
      expect(resolved_result.resolve).to include(
        'group_id' => include(value: Group.last.id)
      )
    end

    context 'when group_id is given in data' do
      let(:data) { { 'group_id' => Group.last.id } }

      it 'returns no new value for group' do
        expect(resolved_result.resolve).to not_include(
          'group_id' => include(value: Group.last.id)
        )
      end
    end

    context 'with different default priority' do
      before do
        Ticket::Priority.find(1).update!(default_create: true)
      end

      it 'returns initial value for priority_id' do
        expect(resolved_result.resolve).to include(
          'priority_id' => include(initialValue: 1)
        )
      end
    end
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'Ticket'
  include_examples 'HasSecurityOptions', type: 'create'
end
