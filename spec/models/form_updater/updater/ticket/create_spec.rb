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
        options: Ticket::State.by_category(:viewable_agent_new).order(name: :asc).map { |state| { value: state.id, label: state.name } },
      },
      'priority_id' => {
        options: Ticket::Priority.where(active: true).order(id: :asc).map { |priority| { value: priority.id, label: priority.name } },
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
  end

  include_examples 'ChecksCoreWorkflow', object_name: 'Ticket'
  include_examples 'HasSecurityOptions'
end
