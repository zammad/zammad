# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Ticket::ScreenOptions

=begin

list of active agents

  result = Ticket::ScreenOptions.agents()

returns

  result = [user1, user2]

=end

  def self.agents
    User.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

=begin

list attributes

  result = Ticket::ScreenOptions.attributes_to_change(
    :ticket_id  => 123,
    :article_id => 123,

    :ticket => ticket_model,
  )

returns

  result = {
    :type_id              => type_ids,
    :state_id             => state_ids,
    :priority_id          => priority_ids,
    :owner_id             => owner_ids,
    :group_id             => group_ids,
    :group_id__owner_id   => groups_users,
  }

=end

  def self.attributes_to_change(params)
    if params[:ticket_id]
      params[:ticket] = self.find( params[:ticket_id] )
    end
    if params[:article_id]
      params[:article] = self.find( params[:article_id] )
    end

    # get ticket states
    state_ids = []
    if params[:ticket]
      state_type = params[:ticket].state.state_type
    end
    state_types = ['open', 'closed', 'pending action', 'pending reminder']
    if state_type && !state_types.include?(state_type.name)
      state_ids.push params[:ticket].state.id
    end
    state_types.each {|type|
      state_type = Ticket::StateType.where( :name => type ).first
      if state_type
        state_type.states.each {|state|
          state_ids.push state.id
        }
      end
    }

    # get owner
    owner_ids = []
    if params[:ticket]
      params[:ticket].agent_of_group.each { |user|
        owner_ids.push user.id
      }
    end

    # get group
    group_ids = []
    Group.where( :active => true ).each { |group|
      group_ids.push group.id
    }

    # get group / user relations
    agents = {}
    Ticket::ScreenOptions.agents.each { |user|
      agents[ user.id ] = 1
    }
    groups_users = {}
    group_ids.each {|group_id|
      groups_users[ group_id ] = []
      Group.find( group_id ).users.each {|user|
        next if !agents[ user.id ]
        groups_users[ group_id ].push user.id
      }
    }

    # get priorities
    priority_ids = []
    Ticket::Priority.where( :active => true ).each { |priority|
      priority_ids.push priority.id
    }

    type_ids = []
    if params[:ticket]
      types = ['note', 'phone']
      if params[:ticket].group.email_address_id
        types.push 'email'
      end
      types.each {|type_name|
        type = Ticket::Article::Type.lookup( :name => type_name )
        if type
          type_ids.push type.id
        end
      }
    end

    return {
      :type_id              => type_ids,
      :state_id             => state_ids,
      :priority_id          => priority_ids,
      :owner_id             => owner_ids,
      :group_id             => group_ids,
      :group_id__owner_id   => groups_users,
    }
  end

=begin

list tickets by customer groupd in state categroie open and closed

  result = Ticket::ScreenOptions.list_by_customer(
    :customer_id     => 123,
    :limit           => 15, # optional, default 15
  )

returns

  result = {
    :open   => tickets_open,
    :closed => tickets_closed,
  }

=end

  def self.list_by_customer(data)

    # get closed/open states
    state_list_open   = Ticket::State.by_category( 'open' )
    state_list_closed = Ticket::State.by_category( 'closed' )

    # get tickets
    tickets_open = Ticket.where(
      :customer_id     => data[:customer_id],
      :state_id => state_list_open
    ).limit( data[:limit] || 15 ).order('created_at DESC')

    tickets_closed = Ticket.where(
      :customer_id     => data[:customer_id],
      :state_id => state_list_closed
    ).limit( data[:limit] || 15 ).order('created_at DESC')

    return {
      :open   => tickets_open,
      :closed => tickets_closed,
    }
  end

end
