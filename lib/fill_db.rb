# rubocop:disable Rails/Output
module FillDB

=begin

fill your database with demo records

  FillDB.load(agents, customers, groups, organizations, tickets)

e. g.

  FillDB.load(10, 100, 5, 40, 1000)

=end

  def self.load( agents, customers, groups, organizations, tickets )
    puts 'load db with:'
    puts " agents:#{agents}"
    puts " customers:#{customers}"
    puts " groups:#{groups}"
    puts " organizations:#{organizations}"
    puts " tickets:#{tickets}"

    # set current user
    UserInfo.current_user_id = 1

    # organizations
    organization_pool = []
    if organizations && !organizations.zero?

      ActiveRecord::Base.transaction do

        (1..organizations).each {
          organization = Organization.create( name: 'FillOrganization::' + rand(999_999).to_s, active: true )
          organization_pool.push organization
        }

      end
    else
      organization_pool = Organization.where(active: true)
      puts " take #{organization_pool.length} organizations"
    end

    # create agents
    agent_pool = []
    if agents && !agents.zero?
      roles = Role.where( name: [ 'Agent'] )
      groups_all = Group.all

      ActiveRecord::Base.transaction do

        (1..agents).each {
          suffix = rand(99_999).to_s
          user = User.create_or_update(
            login: "filldb-agent-#{suffix}",
            firstname: "agent #{suffix}",
            lastname: "agent #{suffix}",
            email: "filldb-agent-#{suffix}@example.com",
            password: 'agentpw',
            active: true,
            roles: roles,
            groups: groups_all,
          )
          agent_pool.push user
        }

      end
    else
      agent_pool = Role.where(name: 'Agent').first.users.where(active: true)
      puts " take #{agent_pool.length} agents"
    end

    # create customer
    customer_pool = []
    if customers && !customers.zero?
      roles = Role.where( name: [ 'Customer'] )
      groups_all = Group.all

      ActiveRecord::Base.transaction do

        (1..customers).each {
          suffix = rand(99_999).to_s
          organization = nil
          if !organization_pool.empty? && rand(2) == 1
            organization = organization_pool[ organization_pool.length - 1 ]
          end
          user = User.create_or_update(
            login: "filldb-customer-#{suffix}",
            firstname: "customer #{suffix}",
            lastname: "customer #{suffix}",
            email: "filldb-customer-#{suffix}@example.com",
            password: 'customerpw',
            active: true,
            organization: organization,
            roles: roles,
          )
          customer_pool.push user
        }

      end
    else
      customer_pool = Role.where(name: 'Customer').first.users.where(active: true)
      puts " take #{customer_pool.length} customers"
    end

    # create groups
    group_pool = []
    if groups && !groups.zero?
      puts "1..#{groups}"

      ActiveRecord::Base.transaction do

        (1..groups).each {
          group = Group.create( name: 'FillGroup::' + rand(999_999).to_s, active: true )
          group_pool.push group
          Role.where(name: 'Agent').first.users.where(active: true).each { |user|
            user_groups = user.groups
            user_groups.push group
            user.groups = user_groups
            user.save
          }
        }

      end
    else
      group_pool = Group.where(active: true)
      puts " take #{group_pool.length} groups"
    end

    # create tickets
    priority_pool = Ticket::Priority.all
    state_pool = Ticket::State.all

    if tickets && !tickets.zero?

      ActiveRecord::Base.transaction do

        (1..tickets).each {
          customer = customer_pool[ rand(customer_pool.length - 1) ]
          agent    = agent_pool[ rand(agent_pool.length - 1) ]
          ticket = Ticket.create(
            title: 'some title äöüß' + rand(999_999).to_s,
            group: group_pool[ rand(group_pool.length - 1) ],
            customer: customer,
            owner: agent,
            state: state_pool[ rand(state_pool.length - 1) ],
            priority: priority_pool[ rand(priority_pool.length - 1) ],
            updated_by_id: agent.id,
            created_by_id: agent.id,
          )
          # create article
          article = Ticket::Article.create(
            ticket_id: ticket.id,
            from: customer.email,
            to: 'some_recipient@example.com',
            subject: 'some subject' + rand(999_999).to_s,
            message_id: 'some@id-' + rand(999_999).to_s,
            body: 'some message ...',
            internal: false,
            sender: Ticket::Article::Sender.where(name: 'Customer').first,
            type: Ticket::Article::Type.where(name: 'phone').first,
            updated_by_id: agent.id,
            created_by_id: agent.id,
          )
        }
      end

    end
  end
end
