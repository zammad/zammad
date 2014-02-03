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
    :ticket_article_type_id => ticket_article_type_ids,
    :ticket_state_id        => ticket_state_ids,
    :ticket_priority_id     => ticket_priority_ids,
    :owner_id               => owner_ids,
    :group_id               => group_ids,
    :group_id__owner_id     => groups_users,
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
    ticket_state_ids = []
    if params[:ticket]
      ticket_state_type = params[:ticket].ticket_state.state_type
    end
    ticket_state_types = ['open', 'closed', 'pending action', 'pending reminder']
    if ticket_state_type && !ticket_state_types.include?(ticket_state_type.name)
      ticket_state_ids.push params[:ticket].ticket_state.id
    end
    ticket_state_types.each {|type|
      ticket_state_type = Ticket::StateType.where( :name => type ).first
      if ticket_state_type
        ticket_state_type.states.each {|ticket_state|
          ticket_state_ids.push ticket_state.id
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
    ticket_priority_ids = []
    Ticket::Priority.where( :active => true ).each { |priority|
      ticket_priority_ids.push priority.id
    }

    ticket_article_type_ids = []
    if params[:ticket]
      ticket_article_types = ['note', 'phone']
      if params[:ticket].group.email_address_id
        ticket_article_types.push 'email'
      end
      ticket_article_types.each {|ticket_article_type_name|
        ticket_article_type = Ticket::Article::Type.lookup( :name => ticket_article_type_name )
        if ticket_article_type
          ticket_article_type_ids.push ticket_article_type.id
        end
      }
    end

    return {
      :ticket_article_type_id => ticket_article_type_ids,
      :ticket_state_id        => ticket_state_ids,
      :ticket_priority_id     => ticket_priority_ids,
      :owner_id               => owner_ids,
      :group_id               => group_ids,
      :group_id__owner_id     => groups_users,
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
    ticket_state_list_open   = Ticket::State.by_category( 'open' )
    ticket_state_list_closed = Ticket::State.by_category( 'closed' )

    # get tickets
    tickets_open = Ticket.where(
      :customer_id     => data[:customer_id],
      :ticket_state_id => ticket_state_list_open
    ).limit( data[:limit] || 15 ).order('created_at DESC')

    tickets_closed = Ticket.where(
      :customer_id     => data[:customer_id],
      :ticket_state_id => ticket_state_list_closed
    ).limit( data[:limit] || 15 ).order('created_at DESC')

    return {
      :open   => tickets_open,
      :closed => tickets_closed,
    }
  end

end
