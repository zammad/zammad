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

  describe 'a list the form holds already' do
    def group_field(known_option_signatures: nil, group_id: ticket.group_id)
      form = FormUpdater::Updater::Ticket::Edit.new(
        context: { current_user: agent }, relation_fields: [{ name: 'group_id', relation: 'group' }, { name: 'state_id', relation: 'TicketState' }],
        meta: { form_id: SecureRandom.uuid, known_option_signatures: }, data: ticket.attributes.slice('state_id').merge('group_id' => group_id), id: Gql::ZammadSchema.id_from_object(ticket)
      )
      form.authorized?
      result = form.resolve

      {
        signature: result[:option_signatures]['group_id'],
        groups:    result[:fields]['group_id'][:options]&.pluck(:label),
        states:    result[:fields]['state_id'][:options]&.pluck(:label),
      }
    end

    def known(field)
      { 'group_id' => field[:signature] }
    end

    it 'gets the groups with a signature, and only the signature once it names it' do
      first = group_field
      again = group_field(known_option_signatures: known(first).merge('state_id' => 'unknown'))

      expect(first).to include(signature: be_present, groups: ['Support'])
      expect(again).to include(signature: first[:signature], groups: nil, states: include('open'))
    end

    it 'gets a list it names all the same where the list lacks the field\'s value, which the form clears only against a list' do
      # With one group to choose from, Core Workflow would set it itself.
      agent.group_names_access_map = { group.name => 'full', create(:group, name: 'Sales').name => 'full', readonly.name => 'read' }
      first = group_field

      expect(group_field(known_option_signatures: known(first), group_id: nil)).to include(signature: first[:signature], groups: nil)
      expect(group_field(known_option_signatures: known(first), group_id: readonly.id)).to include(signature: first[:signature], groups: %w[Sales Support])
    end

    it 'gets a list that was built after the groups to choose from changed with the signature of those groups' do
      create(:core_workflow, :active_and_screen, perform: { 'ticket.group_id' => { 'operator' => 'add_option', 'add_option' => [readonly.id.to_s] } })

      # Between reading what the list is built from and building it: the cache is asked in between.
      granted = false
      allow(Rails.cache).to receive(:read).and_wrap_original do |original, *args|
        if !granted && args.first.to_s.start_with?('FormUpdater::OptionCache')
          granted = true
          agent.group_names_access_map = { group.name => 'full', readonly.name => 'full' }
        end

        original.call(*args)
      end

      during = group_field
      agent.group_names_access_map = { group.name => 'full', readonly.name => 'read' }
      after = group_field

      expect(during).to include(signature: be_present, groups: %w[Archive Support])
      expect(after).to include(signature: be_present.and(not_eq(during[:signature])), groups: ['Support'])
    end

    it 'gets no list at all once it names the signature of each, and a field\'s own options again once the admin changed them', db_strategy: :reset do
      create(:object_manager_attribute_select, name: 'category', data_option: { 'options' => { 'a' => 'Incident', 'b' => 'Change' }, 'default' => '', 'null' => true, 'maxlength' => 255 },
                                               screens: { 'edit' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
      ObjectManager::Attribute.migration_execute

      ticket.update!(owner: agent)

      resolve = lambda do |known_option_signatures|
        form = FormUpdater::Updater::Ticket::Edit.new(
          context: { current_user: agent }, relation_fields: [{ name: 'group_id', relation: 'group' }, { name: 'state_id', relation: 'TicketState' }, { name: 'owner_id', relation: 'user' }],
          meta: { form_id: SecureRandom.uuid, known_option_signatures: }, data: ticket.attributes.slice('group_id', 'state_id', 'owner_id'), id: Gql::ZammadSchema.id_from_object(ticket)
        )
        form.authorized?
        form.resolve
      end
      with_options = ->(result) { result[:fields].select { |_name, field| field.key?(:options) }.keys }

      first = resolve.call(nil)
      again = resolve.call(first[:option_signatures])

      expect(with_options.call(first)).to include('group_id', 'state_id', 'owner_id', 'category')
      expect(first[:option_signatures].keys).to match_array(with_options.call(first))
      expect(with_options.call(again)).to be_empty
      expect(again[:option_signatures]).to eq(first[:option_signatures])

      attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'category')
      attribute.update!(data_option: attribute.data_option.merge('options' => { 'a' => 'Incident', 'b' => 'Change', 'c' => 'Problem' }))
      changed = resolve.call(first[:option_signatures])

      expect(with_options.call(changed)).to eq(['category'])
      expect(changed[:fields]['category'][:options].pluck(:label)).to include('Problem')
    end

    it 'gets the groups again once a group changed, the agent\'s access or what a workflow allows' do
      first = group_field

      travel 1.second
      group.update!(name: 'Helpdesk')
      renamed = group_field(known_option_signatures: known(first))

      agent.group_names_access_map = { group.name => 'full', readonly.name => 'full' }
      more_access = group_field(known_option_signatures: known(renamed))

      create(:core_workflow, :active_and_screen, perform: { 'ticket.group_id' => { 'operator' => 'remove_option', 'remove_option' => [readonly.id.to_s] } })
      restricted = group_field(known_option_signatures: known(more_access))

      expect(renamed[:groups]).to eq(['Helpdesk'])
      expect(more_access[:groups]).to eq(%w[Archive Helpdesk])
      expect(restricted[:groups]).to eq(['Helpdesk'])
      expect([first, renamed, more_access].pluck(:signature).uniq.size).to eq(3)
      expect(restricted[:signature]).not_to eq(more_access[:signature])
    end

    it 'gets a customer\'s groups with a signature as well' do
      Setting.set('customer_ticket_create_group_ids', [group.id, readonly.id])
      form = FormUpdater::Updater::Ticket::Create.new(context: { current_user: create(:customer) }, relation_fields: [{ name: 'group_id', relation: 'group' }], meta: { form_id: SecureRandom.uuid }, data: {})
      form.authorized?

      expect(form.resolve[:option_signatures]['group_id']).to eq(FormUpdater::OptionCache.signature(Service::EntityAttribute::Type::TicketGroup.option_list_key_of([group.id, readonly.id])))
    end
  end
end
