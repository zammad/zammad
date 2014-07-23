module FillDB
  def self.load( agents, customers, groups, organizations, tickets )
    puts "load db with:"
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
      (1..organizations).each {|count|
        organization = Organization.create( :name => 'FillOrganization::' + rand(999999).to_s, :active => true )
        organization_pool.push organization
      }
    else
      organization_pool = Organization.where(:active => true)
    end

    # create agents
    agent_pool = []
    if agents && !agents.zero?
      roles  = Role.where( :name => [ 'Agent'] )
      groups_all = Group.all
      (1..agents).each {|count|
        suffix = rand(99999).to_s
        user = User.create_or_update(
          :login         => "filldb-agent-#{suffix}",
          :firstname     => "agent #{suffix}",
          :lastname      => "agent #{suffix}",
          :email         => "filldb-agent-#{suffix}@example.com",
          :password      => 'agentpw',
          :active        => true,
          :roles         => roles,
          :groups        => groups_all,
        )
        agent_pool.push user
      }
    else
      agent_pool = Role.where(:name => 'Agent').first.users.where(:active => true)
      puts " take #{agent_pool.length} agents"
    end

    # create customer
    customer_pool = []
    if customers && !customers.zero?
      roles  = Role.where( :name => [ 'Customer'] )
      groups_all = Group.all
      (1..customers).each {|count|
        suffix = rand(99999).to_s
        organization = nil
        if !organization_pool.empty? && rand(2) == 1
          organization = organization_pool[ organization_pool.length-1 ]
        end
        user = User.create_or_update(
          :login         => "filldb-customer-#{suffix}",
          :firstname     => "customer #{suffix}",
          :lastname      => "customer #{suffix}",
          :email         => "filldb-customer-#{suffix}@example.com",
          :password      => 'customerpw',
          :active        => true,
          :organization  => organization,
          :roles         => roles,
        )
        customer_pool.push user
      }
    else
      customer_pool = Role.where(:name => 'Customer').first.users.where(:active => true)
    end

    # create groups
    group_pool = []
    if groups && !groups.zero?
      puts "1..#{groups}"
      (1..groups).each {|count|
        group = Group.create( :name => 'FillGroup::' + rand(999999).to_s, :active => true )
        group_pool.push group
        Role.where(:name => 'Agent').first.users.where(:active => true).each {|user|
          user_groups = user.groups
          user_groups.push group
          user.groups = user_groups
          user.save
        }
      }
    else
      group_pool = Group.where(:active => true)
    end

    # create tickets
    priority_pool = Ticket::Priority.all
    state_pool = Ticket::State.all
    if tickets && !tickets.zero?
      (1..tickets).each {|count|
        customer = customer_pool[ rand(customer_pool.length-1) ]
        agent    = agent_pool[ rand(agent_pool.length-1) ]
        ticket = Ticket.create(
          :title          => 'some title äöüß' + rand(999999).to_s,
          :group          => group_pool[ rand(group_pool.length-1) ],
          :customer       => customer,
          :owner          => agent,
          :state          => state_pool[ rand(state_pool.length-1) ],
          :priority       => priority_pool[ rand(priority_pool.length-1) ],
          :updated_by_id  => agent.id,
          :created_by_id  => agent.id,
        )
        # create article
        article = Ticket::Article.create(
          :ticket_id      => ticket.id,
          :from           => customer.email,
          :to             => 'some_recipient@example.com',
          :subject        => 'some subject' + rand(999999).to_s,
          :message_id     => 'some@id-' + rand(999999).to_s,
          :body           => 'some message ...',
          :internal       => false,
          :sender         => Ticket::Article::Sender.where(:name => 'Customer').first,
          :type           => Ticket::Article::Type.where(:name => 'phone').first,
          :updated_by_id  => agent.id,
          :created_by_id  => agent.id,
        )
      }
    end
  end
end