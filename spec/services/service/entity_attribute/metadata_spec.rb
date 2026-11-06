# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::EntityAttribute::Metadata, :aggregate_failures do
  let(:group)  { create(:group, name: 'Support') }
  let(:level2) { create(:group, name: '2nd Level') }
  let(:agent)  { create(:agent, firstname: 'Nina', lastname: 'Agent', email: 'nina@example.com', groups: [group, level2]) }
  let(:ticket) { create(:ticket, group:, state: Ticket::State.lookup(name: 'open')) }

  def fields(changes = {})
    described_class.with_current_user(agent).execute(record: ticket, changes:).index_by(&:name)
  end

  it 'gives the fields of the edit screen with their types, the values Core Workflow allows and their labels' do
    result = fields

    expect(result.keys).to include('group_id', 'owner_id', 'state_id', 'pending_time', 'priority_id')
    expect(result['state_id']).to have_attributes(type: be_a(Service::EntityAttribute::Type::TicketState), shown: true, required: true)
    expect(result['state_id'].choices.map(&:last)).to include('open', 'closed', 'pending reminder')
    expect(result['group_id'].choices.map(&:last)).to eq(['2nd Level', 'Support'])
    expect(result['owner_id'].choices.map(&:last)).to eq(['nobody', 'Nina Agent'])
    expect(result['state_id'].label(ticket.state_id)).to eq('open')
  end

  it 'gives the fields as a change leaves them: pending time required in a pending state, owners of another group' do
    carla = create(:agent, firstname: 'Carla', lastname: 'Second', email: 'carla@example.com', groups: [level2])

    expect(fields['pending_time'].shown).to be(false)
    expect(fields('state_id' => Ticket::State.lookup(name: 'pending reminder').id)['pending_time']).to have_attributes(shown: true, required: true)
    expect(fields('group_id' => level2.id)['owner_id'].allowed).to include(carla.id.to_s)
    expect(fields['owner_id'].allowed).not_to include(carla.id.to_s)
  end

  # The ticket form lists what the layer allows; both have to offer the same values.
  describe 'the values the ticket form offers', db_strategy: :reset do
    let(:sales)  { create(:group, name: 'Sales') }
    let(:emea)   { create(:group, name: 'EMEA', parent: sales) }
    let(:urgent) { create(:ticket_priority, name: '4 urgent') }
    let(:agent)  { create(:agent, firstname: 'Nina', lastname: 'Agent', email: 'nina@example.com', groups: [group, level2, emea]) }
    let(:ticket) { create(:ticket, group: emea, priority: urgent, state: Ticket::State.lookup(name: 'new')) }

    # As the interface asks for them: the updater loads the ticket before it resolves the form.
    def form_options(updater, data:, id: nil, relation_fields: self.relation_fields)
      form = updater.new(context: { current_user: agent }, relation_fields:, meta: { initial: true, form_id: SecureRandom.uuid }, data:, id:)
      form.authorized?

      form.resolve[:fields].transform_values { |field| selectable(Array(field[:options])) }
    end

    # A parent the user may not choose is shown in the tree, but greyed out.
    def selectable(options)
      options.flat_map { |option| [(option[:value].to_s if !option[:disabled]), *selectable(Array(option[:children]))] }.compact
    end

    def relation_fields
      [
        { name: 'group_id', relation: 'group' },
        { name: 'owner_id', relation: 'user' },
        { name: 'state_id', relation: 'TicketState' },
        { name: 'priority_id', relation: 'TicketPriority' },
      ]
    end

    before do
      create(:object_manager_attribute_select, name: 'product', data_option_options: { 'cloud' => 'Zammad Cloud', 'self' => 'Zammad Self-Hosted' },
                                                screens: { 'edit' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
      ObjectManager::Attribute.migration_execute
      create(:agent, groups: [group])
      create(:agent, groups: [level2, emea])
      create(:core_workflow, :active_and_screen, :perform_action, key: 'ticket.product', value: ['cloud'])
      ticket
      urgent.update!(active: false)
    end

    it 'allows the values the edit form offers: a group below another, the state "new" and a priority switched off the ticket holds' do
      form = form_options(FormUpdater::Updater::Ticket::Edit, data: ticket.attributes.slice('group_id', 'owner_id', 'state_id', 'priority_id', 'product'), id: Gql::ZammadSchema.id_from_object(ticket))

      fields.slice('group_id', 'owner_id', 'state_id', 'priority_id', 'product').each do |name, field|
        ours = field.choices.map(&:first)
        ours -= [Service::EntityAttribute::NameMatch::NOBODY_ID.to_s] if name == 'owner_id'

        expect(ours).to match_array(form.fetch(name)), name
      end
      expect(form['group_id']).to include(emea.id.to_s).and(not_include(sales.id.to_s))
      expect(form['state_id']).to include(ticket.state_id.to_s)
      expect(form['priority_id']).to include(urgent.id.to_s)
    end

    it 'lists the same options and labels in the form, the tools and the AI agents' do
      create(:object_manager_attribute_tree_select, name: 'category', screens: { 'edit' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
      ObjectManager::Attribute.migration_execute
      form = FormUpdater::Updater::Ticket::Edit.new(context: { current_user: agent }, relation_fields: [], meta: { initial: true, form_id: SecureRandom.uuid }, data: {}, id: Gql::ZammadSchema.id_from_object(ticket))
      form.authorized?
      listed = form.resolve[:fields]

      %w[product category].each do |name|
        attribute = ObjectManager::Attribute.get(object: 'Ticket', name:)
        listing   = Service::AI::Agent::Run::Context::Instruction::ObjectAttributes.for(attribute)
        ai_agent  = listing.new(object_attribute: attribute).prepare_for_instruction

        expect(fields[name].choices.map(&:first)).to match_array(selectable(listed[name][:options])), name
        expect(ai_agent.pluck(:value)).to match_array(Service::EntityAttribute::Type.unscoped(attribute).choices.map(&:first)), name
      end
      expect(listed['product'][:options]).to eq([{ value: 'self', label: 'Zammad Self-Hosted' }])
      expect(fields['product'].choices).to eq([['self', 'Zammad Self-Hosted']])
    end

    it 'allows the groups, owners, states and priorities the bulk edit form offers, for several tickets and none of them' do
      form    = form_options(FormUpdater::Updater::Ticket::BulkEdit, data: { 'group_id' => emea.id })
      owners  = User.group_access_ids(emea.id, 'full').map(&:to_s)
      allowed = { 'owner_id' => owners }

      %w[group_id owner_id state_id priority_id].each do |name|
        type = Service::EntityAttribute::Type.for(ObjectManager::Attribute.get(object: 'Ticket', name:), user: agent, record: nil)
        ours = type.choices(allowed: allowed[name]).map(&:first)
        ours -= [Service::EntityAttribute::NameMatch::NOBODY_ID.to_s] if name == 'owner_id'

        expect(ours).to match_array(form.fetch(name)), "#{name}: #{ours} / #{form.fetch(name)}"
      end
    end
  end

  describe 'the create screen, for a ticket not saved yet' do
    let(:readonly) { create(:group, name: 'Archive') }

    def create_fields(changes = {})
      agent.group_names_access_map = { group.name => 'full', level2.name => 'full', readonly.name => 'read' }

      described_class.with_current_user(agent).execute(record: Ticket.new, changes:, screen: 'create_middle').index_by(&:name)
    end

    it 'gives the title and the customer above the form\'s fields, the states a ticket starts in and the groups the user may create in' do
      result = create_fields('group_id' => group.id)

      expect(result.keys).to include('title', 'customer_id', 'group_id', 'state_id', 'priority_id')
      expect(result['customer_id'].type).to be_a(Service::EntityAttribute::Type::UserReference)
      expect(result['state_id'].choices.map(&:last)).to match_array(Ticket::State.by_category(:viewable_agent_new).where(active: true).pluck(:name))
      expect(result['state_id'].choices.map(&:last)).not_to include('merged')
      expect(result['group_id'].choices.map(&:last)).to eq(['2nd Level', 'Support'])
    end

    it 'follows the workflows of the create screen' do
      create(:core_workflow, :active_and_screen, :perform_action, screen: 'create_middle', perform: { 'ticket.priority_id' => { 'operator' => 'set_mandatory', 'set_mandatory' => 'true' } })

      expect(create_fields('group_id' => group.id)['priority_id'].required).to be(true)
    end

    it 'offers the values the agent\'s create form offers: groups the agent may create in, the states a ticket starts in', db_strategy: :reset do
      create(:object_manager_attribute_select, name: 'product', data_option_options: { 'cloud' => 'Zammad Cloud', 'self' => 'Zammad Self-Hosted' },
                                                screens: { 'create_middle' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
      ObjectManager::Attribute.migration_execute
      agent.group_names_access_map = { group.name => 'full', level2.name => 'full', readonly.name => 'read' }

      form = FormUpdater::Updater::Ticket::Create.new(
        context:         { current_user: agent },
        relation_fields: [
          { name: 'group_id', relation: 'group' },
          { name: 'owner_id', relation: 'user' },
          { name: 'state_id', relation: 'TicketState' },
          { name: 'priority_id', relation: 'TicketPriority' },
        ],
        meta:            { initial: true, form_id: SecureRandom.uuid },
        data:            { 'group_id' => group.id },
        id:              nil,
      ).tap(&:authorized?).resolve[:fields].transform_values { |field| Array(field[:options]).map { |option| option[:value].to_s } }
      ours = described_class.with_current_user(agent).execute(record: Ticket.new, changes: { 'group_id' => group.id }, screen: 'create_middle').index_by(&:name)

      %w[group_id owner_id state_id priority_id product].each do |name|
        listed = ours[name].choices.map(&:first)
        listed -= [Service::EntityAttribute::NameMatch::NOBODY_ID.to_s] if name == 'owner_id'
        expect(listed).to match_array(form.fetch(name)), "#{name}: #{listed} / #{form.fetch(name)}"
      end
      expect(form.fetch('owner_id')).to include(agent.id.to_s)
      expect(form.fetch('group_id')).not_to include(readonly.id.to_s)
      expect(form.fetch('state_id')).to include(Ticket::State.lookup(name: 'new').id.to_s)
    end
  end

  it 'follows the workflows' do
    create(:core_workflow, :active_and_screen, :perform_action, key: 'ticket.priority_id', value: [Ticket::Priority.lookup(name: '3 high').id.to_s])

    expect(fields['priority_id'].choices.map(&:last)).to eq(['1 low', '2 normal'])
  end

  it 'leaves out a field the user may not see', db_strategy: :reset do
    edit = { 'edit' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } }
    create(:object_manager_attribute_text, name: 'erp_customer', screens: edit)
    create(:object_manager_attribute_text, name: 'billing_code', additional_data_options: { permission: ['admin.user'] }, screens: edit)
    ObjectManager::Attribute.migration_execute

    expect(fields.keys).to include('erp_customer')
    expect(fields.keys).not_to include('billing_code')
  end
end
