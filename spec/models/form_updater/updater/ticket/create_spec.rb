# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

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

  let(:user)    { create(:agent) }
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
        options: Group.where(active: true).order(id: :asc).order(id: :asc).map { |group| { value: group.id, label: group.name } },
      },
      'state_id'    => {
        options: Ticket::State.where(active: true).order(id: :asc).map { |state| { value: state.id, label: state.name } },
      },
      'priority_id' => {
        options: Ticket::Priority.where(active: true).order(id: :asc).map { |priority| { value: priority.id, label: priority.name } },
      },
    }
  end

  context 'when resolving' do
    it 'returns all resolved relation fields with correct value + label' do
      expect(resolved_result.resolve).to eq(expected_result)
    end
  end

  # TODO: Add more tests
  # context 'when using CoreWorkflow' do
  #   it '' do
  #   end
  # end
end
