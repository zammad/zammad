# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'time_calculation'
require 'sla'

class Ticket < ApplicationModel
  before_create   :check_generate, :check_defaults
  before_update   :check_defaults
  before_destroy  :destroy_dependencies
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_destroy   :notify_clients_after_destroy

  belongs_to    :group
  has_many      :articles,              :class_name => 'Ticket::Article', :after_add => :cache_update, :after_remove => :cache_update
  belongs_to    :organization
  belongs_to    :ticket_state,          :class_name => 'Ticket::State'
  belongs_to    :ticket_priority,       :class_name => 'Ticket::Priority'
  belongs_to    :owner,                 :class_name => 'User'
  belongs_to    :customer,              :class_name => 'User'
  belongs_to    :created_by,            :class_name => 'User'
  belongs_to    :create_article_type,   :class_name => 'Ticket::Article::Type'
  belongs_to    :create_article_sender, :class_name => 'Ticket::Article::Sender'

  include Ticket::Escalation
  include Ticket::Subject

  attr_accessor :callback_loop

  def agent_of_group
    Group.find( self.group_id ).users.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

  def self.agents
    User.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

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
    Ticket.agents.each { |user|
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

merge tickets

  ticket = Ticket.find(123)
  result = ticket.merge_to(
    :ticket_id => 123,
  )

returns

  result = true|false

=end

  def merge_to(data)

    # update articles
    Ticket::Article.where( :ticket_id => self.id ).update_all( ['ticket_id = ?', data[:ticket_id] ] )

    # update history

    # create new merge article
    Ticket::Article.create(
      :ticket_id                => self.id,
      :ticket_article_type_id   => Ticket::Article::Type.lookup( :name => 'note' ).id,
      :ticket_article_sender_id => Ticket::Article::Sender.lookup( :name => 'Agent' ).id,
      :body                     => 'merged',
      :internal                 => false
    )

    # add history to both

    # link tickets
    Link.add(
      :link_type                => 'parent',
      :link_object_source       => 'Ticket',
      :link_object_source_value => data[:ticket_id],
      :link_object_target       => 'Ticket',
      :link_object_target_value => self.id
    )

    # set state to 'merged'
    self.ticket_state_id = Ticket::State.lookup( :name => 'merged' ).id

    # rest owner
    self.owner_id = User.where( :login => '-' ).first.id

    # save ticket
    self.save
  end

=begin

check if user has access to ticket

  ticket = Ticket.find(123)
  result = ticket.permission( :current_user => User.find(123) )

returns

  result = true|false

=end

  def permission (data)

    # check customer
    if data[:current_user].is_role('Customer')

      # access ok if its own ticket
      return true if self.customer_id == data[:current_user].id

      # access ok if its organization ticket
      if data[:current_user].organization_id && self.organization_id
        return true if self.organization_id == data[:current_user].organization_id
      end

      # no access
      return false
    end

    # check agent

    # access if requestor is owner
    return true if self.owner_id == data[:current_user].id

    # access if requestor is in group
    data[:current_user].groups.each {|group|
      return true if self.group.id == group.id
    }
    return false
  end

=begin

search tickets

  result = Ticket.search(
    :current_user => User.find(123),
    :query        => 'search something',
    :limit        => 15,
  )

returns

  result = [ticket_model1, ticket_model2]

=end

  def self.search (params)

    # get params
    query        = params[:query]
    limit        = params[:limit] || 12
    current_user = params[:current_user]

    conditions = []
    if current_user.is_role('Agent')
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', current_user.id ).
      where( 'groups.active = ?', true ).
      map( &:id )
      conditions = [ 'group_id IN (?)', group_ids ]
    else
      if !current_user.organization || ( !current_user.organization.shared || current_user.organization.shared == false )
        conditions = [ 'customer_id = ?', current_user.id ]
      else
        conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.id ]
      end
    end

    # do query
    tickets_all = Ticket.select('DISTINCT(tickets.id)').
    where(conditions).
    where( '( `tickets`.`title` LIKE ? OR `tickets`.`number` LIKE ? OR `ticket_articles`.`body` LIKE ? OR `ticket_articles`.`from` LIKE ? OR `ticket_articles`.`to` LIKE ? OR `ticket_articles`.`subject` LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" ).
    joins(:articles).
    limit(limit).
    order('`tickets`.`created_at` DESC')

    # build result list
    tickets = []
    users = {}
    tickets_all.each do |ticket|
      ticket_tmp = Ticket.lookup( :id => ticket.id )
      tickets.push ticket_tmp
    end

    return tickets
  end


=begin

list tickets by customer groupd in state categroie open and closed

  result = Ticket.list_by_customer(
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

  private

  def check_generate
    return if self.number
    self.number = Ticket::Number.generate
  end

  def check_defaults
    if !self.owner_id
      self.owner_id = 1
    end
    #      if self.customer_id && ( !self.organization_id || self.organization_id.empty? )
    if self.customer_id
      customer = User.find( self.customer_id )
      if  self.organization_id != customer.organization_id
        self.organization_id = customer.organization_id
      end
    end
  end

  def destroy_dependencies

    # delete history
    History.remove( 'Ticket', self.id )

    # delete articles
    self.articles.destroy_all
  end

end
