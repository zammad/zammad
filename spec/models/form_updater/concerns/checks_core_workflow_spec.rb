# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Concerns::ChecksCoreWorkflow, :aggregate_failures do
  let(:group)    { create(:group, name: 'Support') }
  let(:readonly) { create(:group, name: 'Archive') }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, group:) }

  def described_form(updater, user:, data:, id: nil, relation_fields: [{ name: 'group_id', relation: 'group' }])
    form = updater.new(context: { current_user: user }, relation_fields:, meta: { initial: true, form_id: SecureRandom.uuid }, data:, id:)
    form.authorized?

    form.resolve[:fields]
  end

  def options(...)
    described_form(...).transform_values { |field| Array(field[:options]).pluck(:value) }
  end

  before do
    agent.group_names_access_map = { group.name => 'full', readonly.name => 'read' }
  end

  it 'offers no record a workflow adds that the field layer does not let the agent choose' do
    create(:core_workflow, :active_and_screen, perform: { 'ticket.group_id' => { 'operator' => 'add_option', 'add_option' => [readonly.id.to_s] } })

    edit = options(FormUpdater::Updater::Ticket::Edit, user: agent, data: ticket.attributes.slice('group_id'), id: Gql::ZammadSchema.id_from_object(ticket))

    expect(edit['group_id']).to include(group.id).and(not_include(readonly.id))
  end

  it 'offers a state and a priority a workflow adds beyond those the forms offer by themselves, as a ticket takes any' do
    merged   = Ticket::State.find_by(name: 'merged')
    inactive = create(:ticket_priority, name: '4 later', active: false)
    create(:core_workflow, :active_and_screen, perform: {
             'ticket.state_id'    => { 'operator' => 'add_option', 'add_option' => [merged.id.to_s] },
             'ticket.priority_id' => { 'operator' => 'add_option', 'add_option' => [inactive.id.to_s] },
           })

    edit = options(FormUpdater::Updater::Ticket::Edit, user: agent, data: ticket.attributes.slice('group_id', 'state_id', 'priority_id'), id: Gql::ZammadSchema.id_from_object(ticket),
                                                       relation_fields: [{ name: 'state_id', relation: 'TicketState' }, { name: 'priority_id', relation: 'TicketPriority' }])

    expect(edit['state_id']).to include(merged.id, ticket.state_id)
    expect(edit['priority_id']).to include(inactive.id, ticket.priority_id)
  end

  it 'keeps the option the admin switched off that the ticket holds, by its place in the tree', db_strategy: :reset do
    create(:object_manager_attribute_tree_select, name: 'category', data_option: {
             'options' => [
               { 'name' => 'Incident', 'value' => 'Incident', 'children' => [{ 'name' => 'Hardware', 'value' => 'Incident::Hardware', 'disabled' => true }] },
               { 'name' => 'Change', 'value' => 'Change' },
             ],
             'default' => '', 'null' => true, 'maxlength' => 255,
           }, screens: { 'edit' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
    ObjectManager::Attribute.migration_execute
    ticket.update!(category: 'Incident::Hardware')

    form = described_form(FormUpdater::Updater::Ticket::Edit, user: agent, data: ticket.attributes.slice('group_id', 'category'), id: Gql::ZammadSchema.id_from_object(ticket))

    expect(form['category'][:options]).to eq([
                                               { value: 'Incident', label: 'Incident', disabled: false, children: [{ value: 'Incident::Hardware', label: 'Hardware', disabled: false }] },
                                               { value: 'Change', label: 'Change', disabled: false },
                                             ])
  end

  it 'lists an owner without a name by the login' do
    nameless = create(:agent, firstname: '', lastname: '', email: '', phone: '', mobile: '', login: 'jdoe', groups: [group])

    form = described_form(FormUpdater::Updater::Ticket::Edit, user: agent, data: ticket.attributes.slice('group_id', 'owner_id'), id: Gql::ZammadSchema.id_from_object(ticket), relation_fields: [{ name: 'owner_id', relation: 'user' }])

    expect(form['owner_id'][:options]).to include({ value: nameless.id, label: 'jdoe' })
  end

  it 'lists an owner without a name but with a phone number by the phone number, as the other forms do' do
    nameless = create(:agent, firstname: '', lastname: '', email: '', phone: '+49 30 123456', mobile: '', login: 'jdoe', groups: [group])

    form = described_form(FormUpdater::Updater::Ticket::Edit, user: agent, data: ticket.attributes.slice('group_id', 'owner_id'), id: Gql::ZammadSchema.id_from_object(ticket), relation_fields: [{ name: 'owner_id', relation: 'user' }])

    expect(form['owner_id'][:options]).to include({ value: nameless.id, label: '+49 30 123456' })
  end

  it 'leaves a customer\'s lists as Core Workflow computes them' do
    Setting.set('customer_ticket_create_group_ids', [group.id, readonly.id])
    customer = create(:customer)

    create = options(FormUpdater::Updater::Ticket::Create, user: customer, data: {})

    expect(create['group_id']).to contain_exactly(group.id, readonly.id)
  end
end
