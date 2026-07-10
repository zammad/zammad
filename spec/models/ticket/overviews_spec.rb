# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Overviews do

  describe '.all' do

    let(:views) { described_class.all(current_user: current_user).map(&:name) }

    shared_examples 'containing' do |overview|
      it "returns #{overview}" do
        expect(views).to include(overview)
      end
    end

    shared_examples 'not containing' do |overview|
      it "doesn't return #{overview}" do
        expect(views).not_to include(overview)
      end
    end

    context 'when Agent' do
      let(:current_user) { create(:agent) }

      it_behaves_like 'containing', 'Open Tickets'
      it_behaves_like 'not containing', 'My Tickets'
      it_behaves_like 'not containing', 'My Organization Tickets'
    end

    context 'when Agent is also Customer' do
      let(:current_user) { create(:agent_and_customer, :with_org) }

      it_behaves_like 'containing', 'Open Tickets'
      it_behaves_like 'containing', 'My Tickets'
      it_behaves_like 'containing', 'My Organization Tickets'
    end

    context 'when Customer' do
      let(:current_user) { create(:customer, :with_org) }

      it_behaves_like 'not containing', 'Open Tickets'
      it_behaves_like 'containing', 'My Tickets'
      it_behaves_like 'containing', 'My Organization Tickets'
    end
  end

  describe '.index' do

    # https://github.com/zammad/zammad/issues/1769
    it 'does not return multiple results for a single ticket' do
      user           = create(:user)
      source_ticket  = create(:ticket, customer: user, created_by_id: user.id)
      source_ticket2 = create(:ticket, customer: user, created_by_id: user.id)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf2@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf4@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf5@blubselector.de', created_by_id: user.id)

      condition = {
        'article.from' => {
          operator: 'contains',
          value:    'blubselector.de',
        },
      }
      overview = create(:overview, condition: condition)

      result = described_class.index(user)
      result = result.select { |x| x[:overview][:name] == overview.name }

      expect(result.count).to eq(1)
      expect(result[0][:count]).to eq(2)
      expect(result[0][:tickets].count).to eq(2)
    end

    # https://github.com/zammad/zammad/issues/3853
    context 'with specific group permissions' do
      let(:group_read)      { create(:group) }
      let(:group_overview)  { create(:group) }
      let(:user)            { create(:agent) }
      let(:ticket_read)     { create(:ticket, group: group_read) }
      let(:ticket_overview) { create(:ticket, group: group_overview) }

      before do
        user.group_names_access_map = {
          group_read.name     => %w[read],
          group_overview.name => %w[read overview],
        }

        create(:mention, mentionable: ticket_read, user: user)
        create(:mention, mentionable: ticket_overview, user: user)
      end

      it 'displays the correct amount of tickets in the sidebar' do
        result = described_class.index(user, ['my_subscribed_tickets'])

        expect(result.first[:count]).to eq(2)
      end

      it 'displays the correct amount of tickets in the list' do
        result = described_class.index(user, ['my_subscribed_tickets'])

        expect(result.first[:tickets].pluck(:id)).to eq([ticket_overview.id, ticket_read.id])
      end
    end
  end

  describe 'Mentions:' do
    let(:group_read) { create(:group) }
    let(:user_read)  { create(:agent) }
    let(:ticket)     { create(:ticket, group: group_read) }

    before do
      user_read.group_names_access_map = {
        group_read.name => 'read',
      }
    end

    it 'does show read only tickets in overview because user is mentioned' do
      create(:mention, mentionable: ticket, user: user_read)
      result = described_class.index(user_read, ['my_subscribed_tickets'])
      expect(result.first[:tickets].pluck(:id)).to eq([ticket.id])
    end

    it 'does not show read only tickets in overview' do
      result = described_class.index(user_read, ['my_subscribed_tickets'])
      expect(result.first[:tickets]).to eq([])
    end
  end

  describe '.tickets_for_overview' do
    it 'does not return multiple results for a single ticket' do
      user           = create(:user)
      source_ticket  = create(:ticket, customer: user, created_by_id: user.id)
      source_ticket2 = create(:ticket, customer: user, created_by_id: user.id)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf2@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf4@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf5@blubselector.de', created_by_id: user.id)

      condition = {
        'article.from' => {
          operator: 'contains',
          value:    'blubselector.de',
        },
      }
      overview = create(:overview, condition: condition)

      result = described_class.tickets_for_overview(overview, user)

      expect(described_class.tickets_for_overview(overview, user).unscope(:order).count(:all).count).to eq(2)
      expect(result.pluck(:id)).to contain_exactly(source_ticket.id, source_ticket2.id)
    end

    context 'with specific group permissions' do
      let(:group_read)      { create(:group) }
      let(:group_overview)  { create(:group) }
      let(:user)            { create(:agent) }
      let(:ticket_read)     { create(:ticket, group: group_read) }
      let(:ticket_overview) { create(:ticket, group: group_overview) }
      let(:overview)        { create(:overview) }

      before do
        user.group_names_access_map = {
          group_read.name     => %w[read],
          group_overview.name => %w[read overview],
        }

        create(:mention, mentionable: ticket_read, user: user)
        create(:mention, mentionable: ticket_overview, user: user)
      end

      it 'displays all tickets when mentioned' do
        overview.update!(condition: { 'ticket.mention_user_ids' => { operator: 'is', value: user.id } })

        result = described_class.tickets_for_overview(overview, user)

        expect(result.pluck(:id)).to contain_exactly(ticket_read.id, ticket_overview.id)
      end

      it 'displays only overview-permitted tickets without mentions' do
        result = described_class.tickets_for_overview(overview, user)

        expect(result.pluck(:id)).to contain_exactly(ticket_overview.id)
      end

      context 'when mentions are used for conditions' do
        let(:group_read) { create(:group) }
        let(:user_read)  { create(:agent) }
        let(:ticket)     { create(:ticket, group: group_read) }
        let(:overview)   { create(:overview) }

        before do
          user_read.group_names_access_map = {
            group_read.name => 'read',
          }
        end

        it 'does show read only tickets in overview because user is mentioned' do
          create(:mention, mentionable: ticket, user: user_read)
          overview.update!(condition: { 'ticket.mention_user_ids' => { operator: 'is', value: user_read.id } })

          result = described_class.tickets_for_overview(overview, user_read)
          expect(result.pluck(:id)).to eq([ticket.id])
        end

        it 'does not show read only tickets in overview' do
          result = described_class.tickets_for_overview(overview, user_read)
          expect(result.pluck(:id)).to be_empty
        end
      end
    end
  end

  describe 'with a custom set of overviews' do
    let(:agent_roles)    { Role.where(name: 'Agent') }
    let(:customer_roles) { Role.where(name: 'Customer') }
    let(:group) do
      Group.create_or_update(
        name:          'OverviewTest',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent1) do
      User.create_or_update(
        login:         'ticket-overview-agent1@example.com',
        firstname:     'Overview',
        lastname:      'Agent1',
        email:         'ticket-overview-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         agent_roles,
        groups:        [group],
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent2) do
      User.create_or_update(
        login:         'ticket-overview-agent2@example.com',
        firstname:     'Overview',
        lastname:      'Agent2',
        email:         'ticket-overview-agent2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         agent_roles,
        # groups: groups,
        updated_at:    '2015-02-05 16:38:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:organization1) do
      Organization.create_or_update(
        name:          'Overview Org',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:customer1) do
      User.create_or_update(
        login:           'ticket-overview-customer1@example.com',
        firstname:       'Overview',
        lastname:        'Customer1',
        email:           'ticket-overview-customer1@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: organization1.id,
        roles:           customer_roles,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end
    let(:customer2) do
      User.create_or_update(
        login:           'ticket-overview-customer2@example.com',
        firstname:       'Overview',
        lastname:        'Customer2',
        email:           'ticket-overview-customer2@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: organization1.id,
        roles:           customer_roles,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end
    let(:customer3) do
      User.create_or_update(
        login:           'ticket-overview-customer3@example.com',
        firstname:       'Overview',
        lastname:        'Customer3',
        email:           'ticket-overview-customer3@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: nil,
        roles:           customer_roles,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end
    let(:agent_overview_role)    { Role.find_by(name: 'Agent') }
    let(:customer_overview_role) { Role.find_by(name: 'Customer') }
    let(:admin_overview_role)    { Role.find_by(name: 'Admin') }
    let(:overview1) do
      Overview.create_or_update(
        name:      'My Assigned Tickets',
        link:      'my_assigned',
        prio:      1000,
        role_ids:  [agent_overview_role.id],
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3, 7],
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:     {
          by:        'created_at',
          direction: 'ASC',
        },
        view:      {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview2) do
      Overview.create_or_update(
        name:      'Unassigned & Open',
        link:      'all_unassigned',
        prio:      1010,
        role_ids:  [agent_overview_role.id],
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
          'ticket.owner_id' => {
            operator: 'is',
            value:    1,
          },
        },
        order:     {
          by:        'created_at',
          direction: 'ASC',
        },
        view:      {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview3) do
      Overview.create_or_update(
        name:      'My Tickets 2',
        link:      'my_tickets_2',
        prio:      1020,
        role_ids:  [agent_overview_role.id],
        user_ids:  [agent2.id],
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3, 7],
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:     {
          by:        'created_at',
          direction: 'ASC',
        },
        view:      {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview4) do
      Overview.create_or_update(
        name:      'My Tickets only with Note',
        link:      'my_tickets_onyl_with_note',
        prio:      1030,
        role_ids:  [agent_overview_role.id],
        user_ids:  [agent1.id],
        condition: {
          'article.type_id' => {
            operator: 'is',
            value:    Ticket::Article::Type.find_by(name: 'note').id,
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:     {
          by:        'created_at',
          direction: 'ASC',
        },
        view:      {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview5) do
      Overview.create_or_update(
        name:      'My Tickets',
        link:      'my_tickets',
        prio:      1100,
        role_ids:  [customer_overview_role.id],
        condition: {
          'ticket.state_id'    => {
            operator: 'is',
            value:    [1, 2, 3, 4, 6, 7],
          },
          'ticket.customer_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title state created_at],
          m:                 %w[number title state created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview6) do
      Overview.create_or_update(
        name:                'My Organization Tickets',
        link:                'my_organization_tickets',
        prio:                1200,
        role_ids:            [customer_overview_role.id],
        organization_shared: true,
        condition:           {
          'ticket.state_id'        => {
            operator: 'is',
            value:    [1, 2, 3, 4, 6, 7],
          },
          'ticket.organization_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        },
        order:               {
          by:        'created_at',
          direction: 'DESC',
        },
        view:                {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview7) do
      Overview.create_or_update(
        name:                'My Organization Tickets (open)',
        link:                'my_organization_tickets_open',
        prio:                1200,
        role_ids:            [customer_overview_role.id],
        user_ids:            [customer2.id],
        organization_shared: true,
        condition:           {
          'ticket.state_id'        => {
            operator: 'is',
            value:    [1, 2, 3],
          },
          'ticket.organization_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        },
        order:               {
          by:        'created_at',
          direction: 'DESC',
        },
        view:                {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview8) do
      Overview.create_or_update(
        name:      'Not Shown Admin',
        link:      'not_shown_admin',
        prio:      9900,
        role_ids:  [admin_overview_role.id],
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [1, 2, 3],
          },
        },
        order:     {
          by:        'created_at',
          direction: 'DESC',
        },
        view:      {
          d:                 %w[title customer state created_at],
          s:                 %w[number title customer state created_at],
          m:                 %w[number title customer state created_at],
          view_mode_default: 's',
        },
      )
    end

    before do
      agent1
      agent2
      customer1
      customer2
      customer3

      Overview.destroy_all
      UserInfo.current_user_id = 1

      overview1
      overview2
      overview3
      overview4
      overview5
      overview6
      overview7
      overview8
    end

    describe '.all' do
      it 'returns the overviews matching the roles and user restrictions of the user', :aggregate_failures do
        result = described_class.all(
          current_user: agent1,
        )

        expect(result.count).to eq(3)
        expect(result[0].name).to eq('My Assigned Tickets')
        expect(result[1].name).to eq('Unassigned & Open')
        expect(result[2].name).to eq('My Tickets only with Note')

        result = described_class.all(
          current_user: agent2,
        )
        expect(result.count).to eq(3)
        expect(result[0].name).to eq('My Assigned Tickets')
        expect(result[1].name).to eq('Unassigned & Open')
        expect(result[2].name).to eq('My Tickets 2')

        result = described_class.all(
          current_user: customer1,
        )
        expect(result.count).to eq(2)
        expect(result[0].name).to eq('My Tickets')
        expect(result[1].name).to eq('My Organization Tickets')

        result = described_class.all(
          current_user: customer2,
        )
        expect(result.count).to eq(3)
        expect(result[0].name).to eq('My Tickets')
        expect(result[1].name).to eq('My Organization Tickets')
        expect(result[2].name).to eq('My Organization Tickets (open)')

        result = described_class.all(
          current_user: customer3,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Tickets')
      end
    end

    describe 'creating an overview' do
      it 'raises an error when the role is missing' do
        Ticket.destroy_all

        expect do
          Overview.create!(
            name:                'new overview',
            link:                'new_overview',
            prio:                1200,
            user_ids:            [customer2.id],
            organization_shared: true,
            condition:           {
              'ticket.state_id'        => {
                operator: 'is',
                value:    [1, 2, 3],
              },
              'ticket.organization_id' => {
                operator:      'is',
                pre_condition: 'current_user.organization_id',
              },
            },
            order:               {
              by:        'created_at',
              direction: 'DESC',
            },
            view:                {
              d:                 %w[title customer state created_at],
              s:                 %w[number title customer state created_at],
              m:                 %w[number title customer state created_at],
              view_mode_default: 's',
            },
          )
        end.to raise_error(Exception)
      end
    end

    describe '.index' do
      it 'returns the overview contents matching conditions and order', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        Ticket.destroy_all

        result = described_class.index(agent1)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank
        expect(result[2][:count]).to eq(0)

        result = described_class.index(agent2)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        ticket1 = Ticket.create!(
          title:         'overview test 1',
          group:         Group.lookup(name: 'OverviewTest'),
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message... 123',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        result = described_class.index(agent1)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:count]).to eq(1)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank
        expect(result[2][:count]).to eq(0)

        result = described_class.index(agent2)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        travel 1.second
        ticket2 = Ticket.create!(
          title:         'overview test 2',
          group:         Group.lookup(name: 'OverviewTest'),
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '3 high'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket::Article.create!(
          ticket_id:     ticket2.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message... 123',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
          type:          Ticket::Article::Type.find_by(name: 'note'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        result = described_class.index(agent1)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket2.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank
        expect(result[2][:count]).to eq(0)

        result = described_class.index(agent2)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        ticket2.owner_id = agent1.id
        ticket2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:count]).to eq(1)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        travel 1.second
        ticket3 = Ticket.create!(
          title:         'overview test 3',
          group:         Group.lookup(name: 'OverviewTest'),
          customer_id:   2,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '1 low'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket::Article.create!(
          ticket_id:     ticket3.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message... 123',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        travel_back

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket3.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        overview2.order = {
          by:        'created_at',
          direction: 'DESC',
        }
        overview2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket3.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket1.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        overview2.order = {
          by:        'priority_id',
          direction: 'DESC',
        }
        overview2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket3.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        overview2.order = {
          by:        'priority_id',
          direction: 'ASC',
        }
        overview2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket3.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket1.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        overview2.order = {
          by:        'priority',
          direction: 'DESC',
        }
        overview2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket3.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank

        overview2.order = {
          by:        'priority',
          direction: 'ASC',
        }
        overview2.save!

        result = described_class.index(agent1)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).not_to be_blank
        expect(result[1][:tickets][0][:id]).to eq(ticket3.id)
        expect(result[1][:tickets][1][:id]).to eq(ticket1.id)
        expect(result[1][:count]).to eq(2)
        expect(result[2][:overview][:id]).to eq(overview4.id)
        expect(result[2][:overview][:name]).to eq('My Tickets only with Note')
        expect(result[2][:overview][:view]).to eq('my_tickets_onyl_with_note')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets][0][:id]).to eq(ticket2.id)
        expect(result[2][:count]).to eq(1)

        result = described_class.index(agent2)
        expect(result[0][:overview][:id]).to eq(overview1.id)
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1][:overview][:id]).to eq(overview2.id)
        expect(result[1][:overview][:name]).to eq('Unassigned & Open')
        expect(result[1][:overview][:view]).to eq('all_unassigned')
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank
        expect(result[1][:count]).to eq(0)
        expect(result[2][:overview][:id]).to eq(overview3.id)
        expect(result[2][:overview][:name]).to eq('My Tickets 2')
        expect(result[2][:overview][:view]).to eq('my_tickets_2')
        expect(result[2][:tickets]).to be_an(Array)
        expect(result[2][:tickets]).to be_blank
      end

      context 'when any owner / no owner is set' do
        it 'returns the tickets matching the owner pre_conditions', :aggregate_failures do
          Ticket.destroy_all
          Overview.destroy_all

          UserInfo.current_user_id = 1
          overview_role = Role.find_by(name: 'Agent')
          overview1 = Overview.create_or_update(
            name:      'not owned',
            prio:      1000,
            role_ids:  [overview_role.id],
            condition: {
              'ticket.owner_id' => {
                operator:      'is',
                pre_condition: 'not_set',
              },
            },
            order:     {
              by:        'created_at',
              direction: 'ASC',
            },
            view:      {
              d:                 %w[title customer group created_at],
              s:                 %w[title customer group created_at],
              m:                 %w[number title customer group created_at],
              view_mode_default: 's',
            },
          )

          overview2 = Overview.create_or_update(
            name:      'not owned by somebody',
            prio:      2000,
            role_ids:  [overview_role.id],
            condition: {
              'ticket.owner_id' => {
                operator:      'is not',
                pre_condition: 'not_set',
              },
            },
            order:     {
              by:        'created_at',
              direction: 'ASC',
            },
            view:      {
              d:                 %w[title customer group created_at],
              s:                 %w[title customer group created_at],
              m:                 %w[number title customer group created_at],
              view_mode_default: 's',
            },
          )

          ticket1 = Ticket.create!(
            title:       'overview test 1',
            group:       Group.lookup(name: 'OverviewTest'),
            customer_id: 2,
            owner_id:    1,
            state:       Ticket::State.lookup(name: 'new'),
            priority:    Ticket::Priority.lookup(name: '2 normal'),
          )

          travel 2.seconds
          ticket2 = Ticket.create!(
            title:       'overview test 2',
            group:       Group.lookup(name: 'OverviewTest'),
            customer_id: 2,
            owner_id:    nil,
            state:       Ticket::State.lookup(name: 'new'),
            priority:    Ticket::Priority.lookup(name: '2 normal'),
          )

          travel 2.seconds
          ticket3 = Ticket.create!(
            title:       'overview test 3',
            group:       Group.lookup(name: 'OverviewTest'),
            customer_id: 2,
            owner_id:    agent1.id,
            state:       Ticket::State.lookup(name: 'new'),
            priority:    Ticket::Priority.lookup(name: '2 normal'),
          )

          result = described_class.index(agent1)
          expect(result[0][:overview][:id]).to eq(overview1.id)
          expect(result[0][:overview][:name]).to eq('not owned')
          expect(result[0][:overview][:view]).to eq('not_owned')
          expect(result[0][:tickets]).to be_an(Array)

          expect(result[0][:tickets][0][:id]).to eq(ticket1.id)
          expect(result[0][:tickets][1][:id]).to eq(ticket2.id)
          expect(result[0][:count]).to eq(2)

          expect(result[1][:overview][:id]).to eq(overview2.id)
          expect(result[1][:overview][:name]).to eq('not owned by somebody')
          expect(result[1][:overview][:view]).to eq('not_owned_by_somebody')
          expect(result[1][:tickets]).to be_an(Array)
          expect(result[1][:tickets][0][:id]).to eq(ticket3.id)
          expect(result[1][:count]).to eq(1)
        end
      end
    end
  end

  describe 'with out of office replacement overviews' do
    let(:agent_roles)    { Role.where(name: 'Agent') }
    let(:customer_roles) { Role.where(name: 'Customer') }
    let(:group) do
      Group.create_or_update(
        name:          'OverviewReplacementTest',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent1) do
      User.create_or_update(
        login:         'ticket-overview-agent1@example.com',
        firstname:     'Overview',
        lastname:      'Agent1',
        email:         'ticket-overview-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         agent_roles,
        groups:        [group],
        out_of_office: false,
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent2) do
      User.create_or_update(
        login:         'ticket-overview-agent2@example.com',
        firstname:     'Overview',
        lastname:      'Agent2',
        email:         'ticket-overview-agent2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         agent_roles,
        groups:        [group],
        out_of_office: false,
        updated_at:    '2015-02-05 16:38:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:organization1) do
      Organization.create_or_update(
        name:          'Overview Org',
        updated_at:    '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:customer1) do
      User.create_or_update(
        login:           'ticket-overview-customer1@example.com',
        firstname:       'Overview',
        lastname:        'Customer1',
        email:           'ticket-overview-customer1@example.com',
        password:        'customerpw',
        active:          true,
        organization_id: organization1.id,
        roles:           customer_roles,
        out_of_office:   false,
        updated_at:      '2015-02-05 16:37:00',
        updated_by_id:   1,
        created_by_id:   1,
      )
    end
    let(:agent_overview_role)    { Role.find_by(name: 'Agent') }
    let(:customer_overview_role) { Role.find_by(name: 'Customer') }
    let(:overview1) do
      Overview.create_or_update(
        name:          'My replacement Tickets',
        link:          'my_replacement',
        prio:          1000,
        role_ids:      [agent_overview_role.id],
        out_of_office: true,
        condition:     {
          'ticket.state_id'                     => {
            operator: 'is',
            value:    Ticket::State.by_category_ids(:open),
          },
          'ticket.out_of_office_replacement_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:         {
          by:        'created_at',
          direction: 'ASC',
        },
        view:          {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview2) do
      Overview.create_if_not_exists(
        name:      'My Assigned Tickets',
        link:      'my_assigned',
        prio:      900,
        role_ids:  [agent_overview_role.id],
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    Ticket::State.by_category_ids(:open),
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order:     {
          by:        'created_at',
          direction: 'ASC',
        },
        view:      {
          d:                 %w[title customer group created_at],
          s:                 %w[title customer group created_at],
          m:                 %w[number title customer group created_at],
          view_mode_default: 's',
        },
      )
    end
    let(:overview3) do
      Overview.create_or_update(
        name:          'My Tickets',
        link:          'my_tickets',
        prio:          1100,
        role_ids:      [customer_overview_role.id],
        out_of_office: false,
        condition:     {
          'ticket.state_id'                     => {
            operator: 'is',
            value:    [1, 2, 3, 4, 6, 7],
          },
          'ticket.out_of_office_replacement_id' => {
            operator:      'is',
            pre_condition: 'current_user.organization_id',
          },
        },
        order:         {
          by:        'created_at',
          direction: 'DESC',
        },
        view:          {
          d:                 %w[title customer state created_at],
          s:                 %w[number title state created_at],
          m:                 %w[number title state created_at],
          view_mode_default: 's',
        },
      )
    end

    before do
      agent1
      agent2
      customer1

      Overview.destroy_all
      UserInfo.current_user_id = 1

      overview1
      overview2
      overview3
    end

    describe '.all' do
      it 'includes the replacement overview only for the replacement agent while out of office', :aggregate_failures do
        result = described_class.all(
          current_user: agent1,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Assigned Tickets')

        result = described_class.all(
          current_user: agent2,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Assigned Tickets')

        result = described_class.all(
          current_user: customer1,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Tickets')

        agent1.out_of_office = true
        agent1.out_of_office_start_at = 2.days.ago
        agent1.out_of_office_end_at = 2.days.from_now
        agent1.out_of_office_replacement_id = agent2.id
        agent1.save!

        result = described_class.all(
          current_user: agent1,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Assigned Tickets')

        result = described_class.all(
          current_user: agent2,
        )
        expect(result.count).to eq(2)
        expect(result[0].name).to eq('My Assigned Tickets')
        expect(result[1].name).to eq('My replacement Tickets')

        result = described_class.all(
          current_user: customer1,
        )
        expect(result.count).to eq(1)
        expect(result[0].name).to eq('My Tickets')
      end
    end

    describe '.index' do
      it 'shows the tickets of the out of office agent to the replacement agent', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        result = described_class.index(agent1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank

        result = described_class.index(agent2)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank

        result = described_class.index(customer1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Tickets')
        expect(result[0][:overview][:view]).to eq('my_tickets')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank

        agent1.out_of_office = true
        agent1.out_of_office_start_at = 2.days.ago
        agent1.out_of_office_end_at = 2.days.from_now
        agent1.out_of_office_replacement_id = agent2.id
        agent1.save!

        expect(agent2.out_of_office_agent_of.count).to eq(1)
        expect(agent2.out_of_office_agent_of[0]).to be_truthy
        expect(agent2.out_of_office_agent_of[0].id).to eq(agent1.id)

        result = described_class.index(agent1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank

        result = described_class.index(agent2)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1]).to be_truthy
        expect(result[1][:overview][:name]).to eq('My replacement Tickets')
        expect(result[1][:overview][:view]).to eq('my_replacement')
        expect(result[1][:count]).to eq(0)
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_blank

        result = described_class.index(customer1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Tickets')
        expect(result[0][:overview][:view]).to eq('my_tickets')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank

        ticket1 = Ticket.create!(
          title:         'overview test 1',
          group:         Group.lookup(name: 'OverviewReplacementTest'),
          customer_id:   2,
          owner_id:      agent1.id,
          state:         Ticket::State.lookup(name: 'new'),
          priority:      Ticket::Priority.lookup(name: '2 normal'),
          updated_by_id: 1,
          created_by_id: 1,
        )
        Ticket::Article.create!(
          ticket_id:     ticket1.id,
          from:          'some_sender@example.com',
          to:            'some_recipient@example.com',
          subject:       'some subject',
          message_id:    'some@id',
          body:          'some message... 123',
          internal:      false,
          sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
          type:          Ticket::Article::Type.find_by(name: 'email'),
          updated_by_id: 1,
          created_by_id: 1,
        )

        result = described_class.index(agent1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(1)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_truthy
        expect(result[0][:tickets][0][:id]).to eq(ticket1.id)

        result = described_class.index(agent2)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Assigned Tickets')
        expect(result[0][:overview][:view]).to eq('my_assigned')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
        expect(result[1]).to be_truthy
        expect(result[1][:overview][:name]).to eq('My replacement Tickets')
        expect(result[1][:overview][:view]).to eq('my_replacement')
        expect(result[1][:count]).to eq(1)
        expect(result[1][:tickets]).to be_an(Array)
        expect(result[1][:tickets]).to be_truthy
        expect(result[1][:tickets][0][:id]).to eq(ticket1.id)

        result = described_class.index(customer1)
        expect(result[0]).to be_truthy
        expect(result[0][:overview][:name]).to eq('My Tickets')
        expect(result[0][:overview][:view]).to eq('my_tickets')
        expect(result[0][:count]).to eq(0)
        expect(result[0][:tickets]).to be_an(Array)
        expect(result[0][:tickets]).to be_blank
      end
    end
  end
end
