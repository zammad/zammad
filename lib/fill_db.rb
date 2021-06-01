# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# rubocop:disable Rails/Output
module FillDB

=begin

fill your database with demo records

  FillDB.load(
    agents: 50,
    customers: 1000,
    groups: 20,
    organizations: 40,
    overviews: 5,
    tickets: 100,
  )

or if you only want to create 100 tickets

  FillDB.load(tickets: 100)
  FillDB.load(agents: 20)
  FillDB.load(overviews: 20)
  FillDB.load(tickets: 10000)

=end

  def self.load(params)
    nice = params[:nice] || 0.5
    agents = params[:agents] || 0
    customers = params[:customers] || 0
    groups = params[:groups] || 0
    organizations = params[:organizations] || 0
    overviews = params[:overviews] || 0
    tickets = params[:tickets] || 0

    puts 'load db with:'
    puts " agents:#{agents}"
    puts " customers:#{customers}"
    puts " groups:#{groups}"
    puts " organizations:#{organizations}"
    puts " overviews:#{overviews}"
    puts " tickets:#{tickets}"

    # set current user
    UserInfo.current_user_id = 1

    # organizations
    organization_pool = []
    if organizations.zero?
      organization_pool = Organization.where(active: true)
      puts " take #{organization_pool.length} organizations"
    else
      (1..organizations).each do
        ActiveRecord::Base.transaction do
          organization = Organization.create!(name: "FillOrganization::#{rand(999_999)}", active: true)
          organization_pool.push organization
        end
      end
    end

    # create agents
    agent_pool = []
    if agents.zero?
      agent_pool = Role.where(name: 'Agent').first.users.where(active: true)
      puts " take #{agent_pool.length} agents"
    else
      roles = Role.where(name: [ 'Agent'])
      groups_all = Group.all

      (1..agents).each do
        ActiveRecord::Base.transaction do
          suffix = rand(99_999).to_s
          user = User.create_or_update(
            login:     "filldb-agent-#{suffix}",
            firstname: "agent #{suffix}",
            lastname:  "agent #{suffix}",
            email:     "filldb-agent-#{suffix}@example.com",
            password:  'agentpw',
            active:    true,
            roles:     roles,
            groups:    groups_all,
          )
          sleep nice
          agent_pool.push user
        end
      end
    end

    # create customer
    customer_pool = []
    if customers.zero?
      customer_pool = Role.where(name: 'Customer').first.users.where(active: true)
      puts " take #{customer_pool.length} customers"
    else
      roles = Role.where(name: [ 'Customer'])
      groups_all = Group.all

      (1..customers).each do
        ActiveRecord::Base.transaction do
          suffix = rand(99_999).to_s
          organization = nil
          if organization_pool.present? && rand(2) == 1
            organization = organization_pool[ organization_pool.length - 1 ]
          end
          user = User.create_or_update(
            login:        "filldb-customer-#{suffix}",
            firstname:    "customer #{suffix}",
            lastname:     "customer #{suffix}",
            email:        "filldb-customer-#{suffix}@example.com",
            password:     'customerpw',
            active:       true,
            organization: organization,
            roles:        roles,
          )
          sleep nice
          customer_pool.push user
        end
      end
    end

    # create groups
    group_pool = []
    if groups.zero?

      group_pool = Group.where(active: true)
      puts " take #{group_pool.length} groups"
    else
      (1..groups).each do
        ActiveRecord::Base.transaction do
          group = Group.create!(name: "FillGroup::#{rand(999_999)}", active: true)
          group_pool.push group
          Role.where(name: 'Agent').first.users.where(active: true).each do |user|
            user_groups = user.groups
            user_groups.push group
            user.groups = user_groups
            user.save!
          end
          sleep nice
        end
      end
    end

    # create overviews
    if !overviews.zero?
      (1..overviews).each do
        ActiveRecord::Base.transaction do
          Overview.create!(
            name:      "Filloverview::#{rand(999_999)}",
            role_ids:  [Role.find_by(name: 'Agent').id],
            condition: {
              'ticket.state_id' => {
                operator: 'is',
                value:    Ticket::State.by_category(:work_on_all).pluck(:id),
              },
            },
            order:     {
              by:        'created_at',
              direction: 'ASC',
            },
            view:      {
              d:                 %w[title customer group state owner created_at],
              s:                 %w[title customer group state owner created_at],
              m:                 %w[number title customer group state owner created_at],
              view_mode_default: 's',
            },
            active:    true
          )
        end
      end
    end

    # create tickets
    priority_pool = Ticket::Priority.all
    state_pool = Ticket::State.all

    return if !tickets || tickets.zero?

    (1..tickets).each do
      ActiveRecord::Base.transaction do
        customer = customer_pool[ rand(customer_pool.length - 1) ]
        agent    = agent_pool[ rand(agent_pool.length - 1) ]
        ticket = Ticket.create!(
          title:         "some title äöüß#{rand(999_999)}",
          group:         group_pool[ rand(group_pool.length - 1) ],
          customer:      customer,
          owner:         agent,
          state:         state_pool[ rand(state_pool.length - 1) ],
          priority:      priority_pool[ rand(priority_pool.length - 1) ],
          updated_by_id: agent.id,
          created_by_id: agent.id,
        )

        # create article
        Ticket::Article.create!(
          ticket_id:     ticket.id,
          from:          customer.email,
          to:            'some_recipient@example.com',
          subject:       "some subject#{rand(999_999)}",
          message_id:    "some@id-#{rand(999_999)}",
          body:          'some message ...',
          internal:      false,
          sender:        Ticket::Article::Sender.where(name: 'Customer').first,
          type:          Ticket::Article::Type.where(name: 'phone').first,
          updated_by_id: agent.id,
          created_by_id: agent.id,
        )
        puts " Ticket #{ticket.number} created"
        sleep nice
      end
    end
  end
end
# rubocop:enable Rails/Output
