# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

# The `approval_state` ticket field may only be changed by an agent or by the
# ticket's assigned approver. For every other user it must be read-only.
RSpec.describe CoreWorkflow::Custom::TicketApprovalState, db_strategy: :reset, type: :model do
  include_context 'with core workflow base'

  let(:organization) { create(:organization, shared: true) }
  let(:requester)    { create(:customer, organization: organization) }
  let(:approver)     { create(:customer, organization: organization) }
  let(:other)        { create(:customer, organization: organization) }
  let(:agent)        { create(:agent, groups: [group]) }

  let(:ticket) do
    create(:ticket,
           group:          group,
           customer:       requester,
           approver:       approver.id.to_s,
           approval_state: 'pending')
  end

  before do
    UserInfo.current_user_id = 1

    add_select_attribute('approver', relation: 'User')
    add_select_attribute('approval_state',
                         options: { 'not_requested' => 'Not requested', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected' })
    ObjectManager::Attribute.migration_execute

    ticket
  end

  def add_select_attribute(name, relation: nil, options: {})
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
      screens:     { 'edit' => { '-all-' => { 'null' => true } } },
      to_create:   true,
      to_migrate:  true,
      to_delete:   false,
    )
  end

  def readonly_for(user)
    payload = base_payload.merge(
      'screen' => 'edit',
      'params' => { 'id' => ticket.id, 'approver' => ticket.approver }
    )
    CoreWorkflow.perform(payload: payload, user: user)[:readonly]['approval_state'] == true
  end

  it 'lets the assigned approver edit the approval state' do
    expect(readonly_for(approver)).to be(false)
  end

  it 'makes the approval state read-only for the requester' do
    expect(readonly_for(requester)).to be(true)
  end

  it 'makes the approval state read-only for another organization member' do
    expect(readonly_for(other)).to be(true)
  end

  it 'lets an agent edit the approval state' do
    expect(readonly_for(agent)).to be(false)
  end
end
