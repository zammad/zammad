# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

# The ticket approval fields (approver, approval_state) are only shown when the
# ticket type is "Approval Request". They default to hidden (shown: false) and
# a Core Workflow reveals them for the matching type.
RSpec.describe 'CoreWorkflow > ticket approval fields shown only for approval request type', db_strategy: :reset, type: :model do
  include_context 'with core workflow base'

  before do
    UserInfo.current_user_id = 1

    add_type_attribute
    add_hidden_select_attribute('approver', relation: 'User')
    add_hidden_select_attribute('approval_state',
                                options: { 'not_requested' => 'Not requested', 'pending' => 'Pending' })
    ObjectManager::Attribute.migration_execute

    create(:core_workflow,
           object:             'Ticket',
           condition_selected: {
             'ticket.type': { operator: 'is', value: ['Approval Request'] },
           },
           perform:            {
             'ticket.approver':       { operator: 'show', show: 'true' },
             'ticket.approval_state': { operator: 'show', show: 'true' },
           })
  end

  def add_type_attribute
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'type',
      display:     'Type',
      data_type:   'select',
      data_option: {
        'default'    => '',
        'options'    => { 'Incident' => 'Incident', 'Approval Request' => 'Approval Request' },
        'nulloption' => true,
        'multiple'   => false,
        'null'       => true,
        'translate'  => true,
      },
      editable:    true,
      active:      true,
      screens:     { 'create_middle' => { '-all-' => { 'null' => true } }, 'edit' => { '-all-' => { 'null' => true } } },
      to_create:   true,
      to_migrate:  true,
      to_delete:   false,
    )
  end

  def add_hidden_select_attribute(name, relation: nil, options: {})
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        name,
      display:     name.humanize,
      data_type:   'select',
      data_option: {
        'default'    => '',
        'relation'   => relation.to_s,
        'options'    => options,
        'nulloption' => true,
        'multiple'   => false,
        'null'       => true,
        'translate'  => false,
      },
      editable:    true,
      active:      true,
      screens:     {
        'create_middle' => { '-all-' => { 'null' => true, 'shown' => false } },
        'edit'          => { '-all-' => { 'null' => true, 'shown' => false } },
      },
      to_create:   true,
      to_migrate:  true,
      to_delete:   false,
    )
  end

  context 'when the ticket type is "Approval Request"' do
    let(:payload) { base_payload.merge('params' => { 'type' => 'Approval Request' }) }

    it 'shows the approver field' do
      expect(result[:visibility]['approver']).to eq('show')
    end

    it 'shows the approval_state field' do
      expect(result[:visibility]['approval_state']).to eq('show')
    end
  end

  context 'when the ticket type is something else' do
    let(:payload) { base_payload.merge('params' => { 'type' => 'Incident' }) }

    it 'does not show the approver field' do
      expect(result[:visibility]['approver']).not_to eq('show')
    end

    it 'does not show the approval_state field' do
      expect(result[:visibility]['approval_state']).not_to eq('show')
    end
  end

  context 'when no ticket type is set' do
    let(:payload) { base_payload.merge('params' => {}) }

    it 'does not show the approver field' do
      expect(result[:visibility]['approver']).not_to eq('show')
    end
  end
end
