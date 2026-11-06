# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::SearchTickets::Filters, :aggregate_failures do
  let(:group)  { create(:group, name: 'Support') }
  let!(:agent) { create(:agent, firstname: 'Nina', lastname: 'Agent', email: 'nina.agent@example.com', groups: [group]) }
  let!(:carla) { create(:customer, firstname: 'Carla', lastname: 'Customer', email: 'carla@example.com', login: 'carla.login') }

  def resolve(arguments)
    described_class.new(user: agent, arguments: arguments.stringify_keys)
  end

  def error_of(arguments)
    resolve(arguments)
    nil
  rescue described_class::Invalid => e
    [e.code, e.message]
  end

  it 'takes no filter from blank values' do
    filters = resolve(customer: ' ', state: [''], owner: nil)

    expect(filters.ids).to be_empty
    expect(filters.descriptions).to be_empty
  end

  describe 'customer' do
    it 'finds a user by email, by login and by the whole name in either order, without regard to case' do
      ['CARLA@example.com', 'carla.login', 'carla customer', 'Customer, Carla'].each do |value|
        expect(resolve(customer: value).ids).to eq(customer_id: [carla.id]), value
      end
    end

    it 'names the user with the email' do
      expect(resolve(customer: 'carla@example.com').descriptions).to eq(['customer Carla Customer (carla@example.com)'])
    end

    it 'finds a user by a part that fits only one' do
      expect(resolve(customer: 'Carl').ids).to eq(customer_id: [carla.id])
    end

    it 'finds an agent who is a ticket\'s customer too' do
      expect(resolve(customer: 'nina.agent@example.com').ids).to eq(customer_id: [agent.id])
    end

    it 'answers a name that fits several users with the candidates and their emails' do
      create(:customer, firstname: 'Carla', lastname: 'Berg', email: 'carla.berg@example.com')

      expect(error_of(customer: 'Carla')).to eq(['ambiguous', 'customer "Carla" matches 2 users: Carla Customer (carla@example.com), Carla Berg (carla.berg@example.com). Use the email, or the ID where there is none.'])
    end

    it 'names candidates without an email by their ID and organization, and finds a user by the ID' do
      organization = create(:organization, name: 'Other GmbH')
      first  = create(:customer, firstname: 'Ben', lastname: 'Example', email: '', login: 'ben-1', organization:)
      second = create(:customer, firstname: 'Ben', lastname: 'Example', email: '', login: 'ben-2')

      expect(error_of(customer: 'Ben Example')).to eq(['ambiguous', "customer \"Ben Example\" matches 2 users: Ben Example (ID #{first.id}, Other GmbH), Ben Example (ID #{second.id}). Use the email, or the ID where there is none."])
      expect(resolve(customer: "ID #{second.id}").ids).to eq(customer_id: [second.id])
      expect(resolve(customer: second.id.to_s).descriptions).to eq(["customer Ben Example (ID #{second.id})"])
    end

    it 'shows five candidates and counts the others' do
      6.times { |index| create(:customer, firstname: 'Max', lastname: "Example#{index}") }

      code, message = error_of(customer: 'Max')

      expect(code).to eq('ambiguous')
      expect(message).to start_with('customer "Max" matches 6 users: ').and end_with(', and 1 more. Use the email, or the ID where there is none.')
      expect(message.scan('Max Example').size).to eq(5)
    end

    it 'answers an unknown name with the closest users' do
      expect(error_of(customer: 'Karla Customer')).to eq(['invalid_value', 'customer "Karla Customer" matches no user. The closest: Carla Customer (carla@example.com).'])
      expect(error_of(customer: 'Zoe')).to eq(['invalid_value', 'customer "Zoe" matches no user.'])
    end

    it 'never takes the system user' do
      expect(error_of(customer: '-')).to include('invalid_value')
    end
  end

  describe 'owner' do
    it 'takes "me" and "nobody"' do
      expect(resolve(owner: 'Me').ids).to eq(owner_id: [agent.id])
      expect(resolve(owner: 'me').descriptions).to eq(['owner Nina Agent (you)'])
      expect(resolve(owner: 'nobody').ids).to eq(owner_id: [1])
    end

    it 'finds an agent by name and by email' do
      berg = create(:agent, firstname: 'Nina', lastname: 'Berg', email: 'nina.berg@example.com')

      expect(resolve(owner: 'Nina Berg').ids).to eq(owner_id: [berg.id])
      expect(resolve(owner: 'nina.berg@example.com').descriptions).to eq(['owner Nina Berg (nina.berg@example.com)'])
      expect(error_of(owner: 'Nina')).to eq(['ambiguous', 'owner "Nina" matches 2 agents: Nina Agent (nina.agent@example.com), Nina Berg (nina.berg@example.com). Use the email, or the ID where there is none.'])
    end

    it 'finds an agent who left, as they still own their tickets' do
      former = create(:agent, firstname: 'Olga', lastname: 'Former', email: 'olga.former@example.com', active: false)

      expect(resolve(owner: 'Olga Former').ids).to eq(owner_id: [former.id])
      expect(resolve(owner: 'olga.former@example.com').ids).to eq(owner_id: [former.id])
    end

    it 'finds no customer as an owner' do
      expect(error_of(owner: 'carla@example.com')).to eq(['invalid_value', 'owner "carla@example.com" matches no agent.'])
    end
  end

  describe 'organization' do
    let!(:example) { create(:organization, name: 'Example Corp') }

    it 'finds an organization by its name and by a part that fits only one' do
      expect(resolve(organization: 'example corp').ids).to eq(organization_id: [example.id])
      expect(resolve(organization: 'Example').descriptions).to eq(['organization Example Corp'])
    end

    it 'answers a part that fits several, and an unknown name with the closest' do
      create(:organization, name: 'Example GmbH')

      expect(error_of(organization: 'Example')).to eq(['ambiguous', 'organization "Example" matches 2 organizations: Example Corp, Example GmbH. Use the full name.'])
      expect(error_of(organization: 'Exmaple Corp')).to eq(['invalid_value', 'organization "Exmaple Corp" matches no organization. The closest: Example Corp.'])
    end

    it 'finds an organization by its ID, as search_organizations names it' do
      ["ID #{example.id}", "id #{example.id}", "##{example.id}", example.id.to_s].each do |value|
        expect(resolve(organization: value).ids).to eq(organization_id: [example.id]), value
      end
      expect(resolve(organization: "ID #{example.id}").descriptions).to eq(['organization Example Corp'])
    end

    it 'finds no organization by an ID that does not exist, not even one whose name holds the ID' do
      create(:organization, name: 'Vendor ID 0815')

      expect(error_of(organization: 'ID 0')).to eq(['invalid_value', 'organization "ID 0" matches no organization.'])
      expect(error_of(organization: '#0')).to eq(['invalid_value', 'organization "#0" matches no organization.'])
    end

    it 'takes a name that is a number as the name where no organization has the number as its ID' do
      numbered = create(:organization, name: '987654321')

      expect(resolve(organization: '987654321').ids).to eq(organization_id: [numbered.id])
    end
  end

  describe 'state and state category' do
    let(:open_ids) { Ticket::State.by_category_ids(:open) }

    it 'takes one or several state names' do
      expect(resolve(state: ['Open']).ids).to eq(state_id: [Ticket::State.lookup(name: 'open').id])
      expect(resolve(state: ['pending reminder', 'pending close']).descriptions).to eq(['state pending reminder, pending close'])
    end

    it 'answers a name that fits several states with them, and an unknown one with the valid states' do
      expect(error_of(state: ['pending'])).to eq(['ambiguous', 'state "pending" matches 2 states: pending reminder, pending close. Use the full name, or pass several.'])
      expect(error_of(state: ['done'])).to eq(['invalid_value', "state \"done\" does not exist. Valid states: #{Ticket::State.reorder(:id).pluck(:name).join(', ')}."])
    end

    it 'takes a state category as GraphQL does' do
      expect(resolve(state_type_category: 'open').ids).to eq(state_id: open_ids)
      expect(resolve(state_type_category: 'open').descriptions).to eq(['state category open'])
      expect(open_ids).to include(Ticket::State.lookup(name: 'new').id, Ticket::State.lookup(name: 'pending close').id)
    end

    it 'takes the states of a category only, and none where they exclude each other' do
      filters = resolve(state_type_category: 'open', state: %w[new closed])

      expect(filters.ids).to eq(state_id: [Ticket::State.lookup(name: 'new').id])
      expect(filters.match_nothing?).to be(false)
      expect(resolve(state_type_category: 'open', state: ['closed']).match_nothing?).to be(true)
    end
  end

  describe 'group' do
    let(:europe) { create(:group, name: 'Europe', parent: create(:group, name: 'Sales')) }
    let!(:agent) { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group, europe]) }

    before { create(:group, name: 'Payroll') }

    it 'finds a group of the user by its full name, with either separator, or by its last part' do
      ['Sales › Europe', 'sales::europe', 'Sales > Europe', 'Europe'].each do |value|
        expect(resolve(group: value).ids).to eq({ group_id: [europe.id] }), value
      end
      expect(resolve(group: 'Europe').descriptions).to eq(['group Sales › Europe'])
    end

    it 'answers a group the user has no access to as unknown, naming the user\'s groups only' do
      expect(error_of(group: 'Payroll')).to eq(['invalid_value', 'group "Payroll" does not exist. Valid groups: Support, Sales › Europe.'])
    end
  end

  describe 'priority' do
    it 'finds a priority by its name and by a part' do
      expect(resolve(priority: '3 high').ids).to eq(priority_id: [Ticket::Priority.lookup(name: '3 high').id])
      expect(resolve(priority: 'high').descriptions).to eq(['priority 3 high'])
      expect(error_of(priority: 'urgent')).to eq(['invalid_value', 'priority "urgent" does not exist. Valid priorities: 1 low, 2 normal, 3 high.'])
    end
  end

  describe 'the conditions' do
    let(:filters) { resolve(customer: 'carla@example.com', owner: 'nobody', state_type_category: 'closed') }

    it 'gives every filter to the search as a condition' do
      expect(filters.conditions).to eq(
        'ticket.customer_id' => { operator: 'is', value: [carla.id] },
        'ticket.owner_id'    => { operator: 'is', value: [1] },
        'ticket.state_id'    => { operator: 'is', value: Ticket::State.by_category_ids(:closed) },
      )
    end

    it 'checks the hits against every filter in the database' do
      match = create(:ticket, customer: carla, state_name: 'closed')
      create(:ticket, customer: carla, state_name: 'open')
      create(:ticket, customer: carla, state_name: 'closed', owner: agent)

      expect(filters.apply(Ticket.all)).to contain_exactly(match)
    end
  end
end
