# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::EntityAttribute::Type, :aggregate_failures do
  let(:group) { create(:group, name: 'Support') }
  let(:agent) { create(:agent, firstname: 'Nina', lastname: 'Agent', email: 'nina@example.com', groups: [group]) }

  def type_of(attribute)
    described_class.for(attribute, user: agent)
  end

  def ticket_field(name)
    ObjectManager::Attribute.get(object: 'Ticket', name:)
  end

  # The tools word the errors for the model.
  def error_of(type, value)
    error_of_allowed(type, value, nil)
  end

  def error_of_allowed(type, value, allowed)
    type.resolve(value, allowed:)
    nil
  rescue described_class::Invalid => e
    [e.code, Service::AI::Tool::Fields::EntityAttribute.message(e)]
  end

  # The candidates of a name a strict match refuses because it fits only by a part.
  def candidates_by_part(type, value)
    type.resolve(value)
    nil
  rescue described_class::Invalid => e
    e.items if e.code == 'ambiguous' && e.reason == :partial
  end

  describe '.for' do
    it 'finds a class by the field\'s relation first, else by its data type, without a list' do
      expect(type_of(ticket_field('state_id'))).to be_a(described_class::TicketState)
      expect(type_of(ticket_field('owner_id'))).to be_a(described_class::Owner)
      expect(type_of(ticket_field('group_id'))).to be_a(described_class::TicketGroup)
      expect(type_of(ticket_field('pending_time'))).to be_a(described_class::Timestamp)
      expect(type_of(build(:object_manager_attribute_select))).to be_a(described_class::Select)
      expect(type_of(build(:object_manager_attribute_user_autocompletion))).to be_a(described_class::UserReference)
    end

    it 'finds a class an addon adds with a file of its own' do
      stub_const('Service::EntityAttribute::Type::Color', Class.new(described_class) { handles 'color' })
      attribute = build(:object_manager_attribute_text, data_type: 'color')

      expect(type_of(attribute)).to be_a(Service::EntityAttribute::Type::Color)
    end

    it 'shows a field of a type without a class as it is stored, and sets nothing' do
      type = type_of(build(:object_manager_attribute_organization_autocompletion, name: 'partner'))

      expect(type.label(42)).to eq(42)
      expect(type.settable?).to be(false)
      expect(error_of(type, 'Example Corp')).to eq(['not_settable', 'partner cannot be set with this tool. Change it in Zammad.'])
    end

    it 'reads a field for a user, and for nobody only through .unscoped' do
      expect { described_class.for(ticket_field('group_id'), user: nil) }.to raise_error(ArgumentError)
      expect(described_class.unscoped(ticket_field('group_id'))).to be_a(described_class::TicketGroup)
    end
  end

  describe '.unscoped' do
    it 'lists every active value of a field, whatever a user may choose' do
      other    = create(:group, name: 'Other')
      inactive = create(:group, name: 'Old', active: false)
      sales    = create(:agent, firstname: 'Sam', lastname: 'Sales', groups: [other])
      groups   = described_class.unscoped(ticket_field('group_id')).records

      expect(groups).to include(group, other).and(not_include(inactive))
      expect(described_class.unscoped(ticket_field('owner_id')).records).to include(agent, sales).and(not_include(User.find(1)))
      expect(described_class.unscoped(ticket_field('state_id')).records).to include(Ticket::State.lookup(name: 'merged'))
      expect(described_class.unscoped(build(:object_manager_attribute_user_autocompletion)).label(sales.id)).to eq('Sam Sales')
    end
  end

  describe 'Text' do
    let(:type) { type_of(build(:object_manager_attribute_text, name: 'erp_customer', data_option: { 'type' => 'text', 'maxlength' => 10 })) }

    it 'takes text within the field\'s length' do
      expect(type.resolve('ACME')).to eq('ACME')
      expect(type.resolve(nil)).to be_nil
      expect(type.free_text?).to be(true)
      expect(error_of(type, 'A' * 11)).to eq(['invalid_value', 'erp_customer: the value has 11 characters; at most 10 fit.'])
      expect(error_of(type, 7)).to eq(['invalid_value', 'erp_customer: give the value as text.'])
    end
  end

  describe 'RichText' do
    let(:type) { type_of(build(:object_manager_attribute_text, name: 'summary', data_type: 'richtext')) }

    it 'stores plain text as HTML and reads it as plain text' do
      expect(type.resolve("Line one\n<b>two</b>")).to eq('Line one<br>&lt;b&gt;two&lt;/b&gt;')
      expect(type.plain('<p>Line one</p>')).to eq('Line one')
    end
  end

  describe 'Select' do
    let(:attribute) do
      build(:object_manager_attribute_select, name: 'product', data_option_options: { 'cloud' => 'Zammad Cloud', 'self' => 'Zammad Self-Hosted', 'plus' => 'Zammad Plus' })
    end
    let(:type) { type_of(attribute) }

    it 'takes an option by its label or its key, also by a part that fits one, and stores its key' do
      expect(type.resolve('zammad cloud')).to eq('cloud')
      expect(type.resolve('self')).to eq('self')
      expect(type.resolve('Hosted')).to eq('self')
      expect(type.label('cloud')).to eq('Zammad Cloud')
    end

    it 'names the candidates of an ambiguous label and the options of an unknown one' do
      expect(error_of(type, 'Zammad')).to eq(['ambiguous', 'product "Zammad" matches 3 options: Zammad Cloud, Zammad Plus, Zammad Self-Hosted. Use the full name.'])
      expect(error_of(type, 'Desk')).to eq(['invalid_value', 'product "Desk" does not exist. Valid options: Zammad Cloud, Zammad Plus, Zammad Self-Hosted.'])
    end

    it 'lists the options Core Workflow allows, by their labels' do
      expect(type.choices.map(&:last)).to eq(['Zammad Cloud', 'Zammad Plus', 'Zammad Self-Hosted'])
      expect(type.choices(allowed: ['', 'plus']).map(&:last)).to eq(['Zammad Plus'])
    end

    it 'takes several options for a multiselect, and empties it' do
      multi = type_of(build(:object_manager_attribute_multiselect, name: 'products', data_option_options: attribute.data_option['options']))

      expect(multi.resolve(['Zammad Cloud', 'plus'])).to eq(%w[cloud plus])
      expect(multi.resolve('Zammad Cloud')).to eq(['cloud'])
      expect(multi.resolve(nil)).to eq([])
      expect(multi.label(%w[cloud plus])).to eq(['Zammad Cloud', 'Zammad Plus'])
    end

    it 'takes no option the admin disabled, and still reads it' do
      options = [{ 'name' => 'Old product', 'value' => 'old', 'disabled' => true }, { 'name' => 'New product', 'value' => 'new' }]
      type    = type_of(build(:object_manager_attribute_select, name: 'product', data_option_options: options))

      expect(type.choices.map(&:last)).to eq(['New product'])
      expect(error_of(type, 'Old product').first).to eq('invalid_value')
      expect(type.label('old')).to eq('Old product')
    end
  end

  describe 'TreeSelect' do
    let(:type) { type_of(build(:object_manager_attribute_tree_select, name: 'category')) }

    it 'takes an option by its path as the UI joins it, or by a last part that fits one' do
      expect(type.resolve('Incident › Hardware › Mouse')).to eq('Incident::Hardware::Mouse')
      expect(type.resolve('Incident::Hardware::Mouse')).to eq('Incident::Hardware::Mouse')
      expect(type.resolve('Keyboard')).to eq('Incident::Hardware::Keyboard')
      expect(type.label('Incident::Hardware::Mouse')).to eq('Incident::Hardware::Mouse')
    end
  end

  describe 'Boolean, Number and CalendarDate' do
    it 'takes values of their JSON types only, within bounds' do
      boolean = type_of(build(:object_manager_attribute_boolean, name: 'vip_support'))
      number  = type_of(build(:object_manager_attribute_integer, name: 'seats'))
      date    = type_of(build(:object_manager_attribute_date, name: 'renewal'))

      expect([boolean.resolve(true), boolean.label(true), boolean.label(false)]).to eq([true, 'yes', 'no'])
      expect(error_of(boolean, 'yes').first).to eq('invalid_value')
      expect(number.resolve(12)).to eq(12)
      expect(error_of(number, 10_000)).to eq(['invalid_value', 'seats: the value must be at most 9999.'])
      expect(error_of(number, '12').first).to eq('invalid_value')
      expect(date.resolve('2026-10-26')).to eq('2026-10-26')
      expect(error_of(date, 'next Monday')).to eq(['invalid_value', 'renewal: "next Monday" is no date; give it as YYYY-MM-DD.'])
    end
  end

  describe 'Timestamp' do
    let(:type) { type_of(ticket_field('pending_time')) }

    before { Setting.set('timezone_default', 'Europe/Berlin') }

    it 'takes ISO 8601 and the form the tools show, in the system time zone where no offset is given' do
      expect(type.resolve('2026-10-26T09:00:00+01:00')).to eq(Time.utc(2026, 10, 26, 8))
      expect(type.resolve('2026-10-26T09:00')).to eq(Time.utc(2026, 10, 26, 8))
      expect(type.resolve('2026-10-26 09:00')).to eq(Time.utc(2026, 10, 26, 8))
      expect(type.label(Time.utc(2026, 10, 26, 8))).to eq('2026-10-26 09:00')
      expect(error_of(type, 'Monday morning').first).to eq('invalid_value')
    end
  end

  describe 'TicketState and TicketPriority' do
    it 'take an active record by name and set it as the record' do
      expect(type_of(ticket_field('state_id')).resolve('Pending Close')).to eq(Ticket::State.lookup(name: 'pending close'))
      expect(type_of(ticket_field('priority_id')).resolve('3 high')).to eq(Ticket::Priority.lookup(name: '3 high'))
      expect(type_of(ticket_field('state_id')).data_key).to eq('state')
      expect(error_of(type_of(ticket_field('state_id')), 'pending').first).to eq('ambiguous')
    end

    it 'take a record by a part that fits one, as a state or a priority names no one' do
      expect(type_of(ticket_field('state_id')).resolve('remind')).to eq(Ticket::State.lookup(name: 'pending reminder'))
      expect(type_of(ticket_field('priority_id')).resolve('high')).to eq(Ticket::Priority.lookup(name: '3 high'))
    end

    it 'takes and names only the states the edit form offers, and the ticket\'s own' do
      ticket = create(:ticket, state: Ticket::State.lookup(name: 'new'))
      state  = ticket_field('state_id')

      expect(error_of(type_of(state), 'foo').last).to include('Valid states:').and(include('open')).and(not_include('new,', 'merged'))
      expect(error_of(type_of(state), 'merged').first).to eq('invalid_value')
      expect(described_class.for(state, user: agent, record: ticket).resolve('new')).to eq(Ticket::State.lookup(name: 'new'))
    end

    it 'keeps the ticket\'s own priority a choice after it was switched off' do
      urgent = create(:ticket_priority, name: '4 urgent')
      ticket = create(:ticket, group:, priority: urgent)
      urgent.update!(active: false)

      expect(described_class.for(ticket_field('priority_id'), user: agent, record: ticket).choices.map(&:last)).to include('4 urgent')
      expect(type_of(ticket_field('priority_id')).choices.map(&:last)).not_to include('4 urgent')
    end

    it 'lists the states Core Workflow allows' do
      allowed = Ticket::State.where(name: %w[open closed]).pluck(:id).map(&:to_s)

      expect(type_of(ticket_field('state_id')).choices(allowed: ['', *allowed]).map(&:last)).to eq(%w[closed open])
    end
  end

  describe 'TicketGroup' do
    let(:type) { type_of(ticket_field('group_id')) }

    it 'lists groups below others with their parents, those not among them disabled, with one query for all parents' do
      sales  = create(:group, name: 'Sales')
      emea   = create(:group, name: 'EMEA', parent: sales)
      berlin = create(:group, name: 'Berlin', parent: emea)
      paris  = create(:group, name: 'Paris', parent: emea)
      groups = Group.where(id: [berlin.id, paris.id, group.id]).reorder(:name).to_a

      queries = 0
      counter = ->(*, payload) { queries += 1 if payload[:sql].exclude?('SAVEPOINT') }
      options = ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { described_class::TicketGroup.option_list_of(groups) }

      expect(options.map { |option| [option.label, option.disabled] }).to eq([['Sales', true], ['Support', false]])
      expect(options.first.children.map(&:label)).to eq(['EMEA'])
      expect(options.first.children.first.children.map { |option| [option.label, option.disabled] }).to eq([['Berlin', false], ['Paris', false]])
      expect(queries).to eq(1)
    end

    it 'takes a group the user may move a ticket to, by its path or its last part' do
      level2 = create(:group, name_last: '2nd Level', parent_id: group.id)
      agent.group_names_access_map = { 'Support' => 'full', level2.name => 'change' }

      expect(type.resolve('Support › 2nd Level')).to eq(level2)
      expect(type.resolve('2nd level')).to eq(level2)
      expect(type.label(level2.id)).to eq('Support › 2nd Level')
    end

    it 'names the group a name fits only by a part, and takes none' do
      level2   = create(:group, name_last: '2nd Level', parent_id: group.id)
      presales = create(:group, name: 'Presales')
      agent.group_names_access_map = { 'Support' => 'full', level2.name => 'change', presales.name => 'full' }

      expect(candidates_by_part(type, 'Sales')).to eq([presales])
      expect(candidates_by_part(type, 'Support › 2nd')).to eq([level2])
      expect(candidates_by_part(type, '2nd')).to eq([level2])
      expect(error_of(type, 'Supp').first).to eq('ambiguous')
    end

    it 'answers a group the user may only read, or not see, like one that does not exist' do
      create(:group, name: 'Finance')
      read_only = create(:group, name: 'Sales')
      agent.group_names_access_map = { 'Support' => 'full', read_only.name => 'read' }

      expect(error_of(type, 'Finance')).to eq(['invalid_value', 'group "Finance" does not exist. Valid groups: Support.'])
      expect(error_of(type, 'Sales')).to eq(['invalid_value', 'group "Sales" does not exist. Valid groups: Support.'])
    end
  end

  describe 'Owner' do
    let(:type)   { type_of(ticket_field('owner_id')) }
    let!(:carla) { create(:agent, firstname: 'Carla', lastname: 'Agent', email: 'carla.agent@example.com') }

    it 'takes an active agent, "me" and "nobody"' do
      expect(type.resolve('carla.agent@example.com')).to eq(carla)
      expect(type.resolve('me')).to eq(agent)
      expect(type.resolve('Nobody').id).to eq(1)
      expect(type.label(1)).to eq('nobody')
      expect(type.label(carla.id)).to eq('Carla Agent')
    end

    it 'names the candidates of a name two agents share, and no customer' do
      other = create(:agent, firstname: 'Carla', lastname: 'Other', email: 'carla.other@example.com')
      create(:customer, firstname: 'Carla', lastname: 'Customer')

      expect(error_of(type, 'Carla')).to eq(['ambiguous', "owner \"Carla\" matches 2 agents: Carla Agent (carla.agent@example.com), Carla Other (#{other.email}). Use the email, or the ID where there is none."])
    end

    it 'takes an agent by ID, email, login and the whole name in either order' do
      ["ID #{carla.id}", carla.id.to_s, 'CARLA.AGENT@example.com', carla.login, 'carla agent', 'Agent, Carla'].each do |name|
        expect(type.resolve(name)).to eq(carla), name
      end
    end

    it 'names the agent a name fits only by a part, a whole first or last name alone too, and takes none' do
      hannah = create(:agent, firstname: 'Hannah', lastname: 'Smith', email: 'hannah@example.com')

      expect(candidates_by_part(type, 'Anna')).to eq([hannah])
      expect(candidates_by_part(type, 'Smith')).to eq([hannah])
      expect(candidates_by_part(type, 'Carla')).to eq([carla])
      expect(candidates_by_part(type, 'hannah@example')).to eq([hannah])
    end

    it 'names the owners the ticket allows where "me" or an agent may not own it' do
      allowed = ['', carla.id.to_s]

      expect(error_of_allowed(type, 'me', allowed)).to eq(['invalid_value', 'owner "me": you may not own this ticket. Valid owners: nobody, Carla Agent (carla.agent@example.com).'])
      expect(error_of_allowed(type, 'Nina', allowed)).to eq(['invalid_value', 'owner "Nina" matches no agent who may own this ticket. Valid owners: nobody, Carla Agent (carla.agent@example.com).'])
    end

    it 'lists the owners Core Workflow allows, nobody among them, by name as the form does' do
      expect(type.choices(allowed: ['', carla.id.to_s]).map(&:last)).to eq(['nobody', 'Carla Agent'])
    end
  end

  describe 'UserReference' do
    let(:type) { type_of(build(:object_manager_attribute_user_autocompletion, name: 'reviewer')) }

    it 'takes a user the user may see and stores the ID' do
      reviewer = create(:customer, firstname: 'Rita', lastname: 'Reviewer', email: 'rita@example.com')

      expect(type.resolve('rita@example.com')).to eq(reviewer.id)
      expect(type.label(reviewer.id)).to eq('Rita Reviewer')
    end

    it 'names the user a name fits only by a part, and takes the whole name' do
      reviewer = create(:customer, firstname: 'Rita', lastname: 'Reviewer', email: 'rita@example.com')

      expect(candidates_by_part(type, 'Rita')).to eq([reviewer])
      expect(type.resolve('Rita Reviewer')).to eq(reviewer.id)
    end
  end
end
