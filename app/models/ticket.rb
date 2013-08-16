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

  result = Ticket.find(123).merge_to(
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

build new subject with ticket number in there

  ticket = Ticket.find(123)
  result = ticket.subject_build('some subject')

returns

  result = "[Ticket#1234567] some subject"

=end

  def subject_build (subject)

    # clena subject
    subject = self.subject_clean(subject)

    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')

    # none position
    if Setting.get('ticket_hook_position') == 'none'
      return subject
    end

    # right position
    if Setting.get('ticket_hook_position') == 'right'
      return subject + " [#{ticket_hook}#{ticket_hook_divider}#{self.number}] "
    end

    # left position
    return "[#{ticket_hook}#{ticket_hook_divider}#{self.number}] " + subject
  end

=begin

clean subject remove ticket number and other not needed chars

  ticket = Ticket.find(123)
  result = ticket.subject_clean('[Ticket#1234567] some subject')

returns

  result = "some subject"

=end

  def subject_clean (subject)
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')
    ticket_subject_size = Setting.get('ticket_subject_size')

    # remove all possible ticket hook formats with []
    subject = subject.gsub /\[#{ticket_hook}: #{self.number}\](\s+?|)/, ''
    subject = subject.gsub /\[#{ticket_hook}:#{self.number}\](\s+?|)/, ''
    subject = subject.gsub /\[#{ticket_hook}#{ticket_hook_divider}#{self.number}\](\s+?|)/, ''

    # remove all possible ticket hook formats without []
    subject = subject.gsub /#{ticket_hook}: #{self.number}(\s+?|)/, ''
    subject = subject.gsub /#{ticket_hook}:#{self.number}(\s+?|)/, ''
    subject = subject.gsub /#{ticket_hook}#{ticket_hook_divider}#{self.number}(\s+?|)/, ''

    # remove leading "..:\s" and "..[\d+]:\s" e. g. "Re: " or "Re[5]: "
    subject = subject.gsub /^(..(\[\d+\])?:\s)+/, ''

    # resize subject based on config
    if subject.length > ticket_subject_size.to_i
      subject = subject[ 0, ticket_subject_size.to_i ] + '[...]'
    end

    return subject
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

overview list

  result = Ticket.overview_list(
    :current_user => User.find(123),
  )

returns

  result = [overview1, overview2]

=end

  def self.overview_list (data)

    # get customer overviews
    if data[:current_user].is_role('Customer')
      role = data[:current_user].is_role( 'Customer' )
      if data[:current_user].organization_id && data[:current_user].organization.shared
        overviews = Overview.where( :role_id => role.id, :active => true )
      else
        overviews = Overview.where( :role_id => role.id, :organization_shared => false, :active => true )
      end
      return overviews
    end

    # get agent overviews
    role = data[:current_user].is_role( 'Agent' )
    overviews = Overview.where( :role_id => role.id, :active => true )
    return overviews
  end

=begin

search tickets

  result = Ticket.overview_list(
    :current_user => User.find(123),
    :view         => 'some_view_url',
  )

returns

  result = {
    :tickets       => tickets,                # [ticket1, ticket2, ticket3]
    :tickets_count => tickets_count,          # count of tickets
    :overview      => overview_selected_raw,  # overview attributes
  }

=end

  def self.overview (data)

    overviews = self.overview_list(data)

    # build up attributes hash
    overview_selected     = nil
    overview_selected_raw = nil

    overviews.each { |overview|

      # remember selected view
      if data[:view] && data[:view] == overview.link
        overview_selected     = overview
        overview_selected_raw = Marshal.load( Marshal.dump(overview.attributes) )
      end

      # replace e.g. 'current_user.id' with current_user.id
      overview.condition.each { |item, value |
        if value && value.class.to_s == 'String'
          parts = value.split( '.', 2 )
          if parts[0] && parts[1] && parts[0] == 'current_user'
            overview.condition[item] = data[:current_user][parts[1].to_sym]
          end
        end
      }
    }

    if data[:view] && !overview_selected
      return
    end

    # sortby
    # prio
    # state
    # group
    # customer

    # order
    # asc
    # desc

    # groupby
    # prio
    # state
    # group
    # customer

    #    all = attributes[:myopenassigned]
    #    all.merge( { :group_id => groups } )

    #    @tickets = Ticket.where(:group_id => groups, attributes[:myopenassigned] ).limit(params[:limit])
    # get only tickets with permissions
    if data[:current_user].is_role('Customer')
      group_ids = Group.select( 'groups.id' ).
      where( 'groups.active = ?', true ).
      map( &:id )
    else
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', [ data[:current_user].id ] ).
      where( 'groups.active = ?', true ).
      map( &:id )
    end

    # overview meta for navbar
    if !overview_selected

      # loop each overview
      result = []
      overviews.each { |overview|

        # get count
        count = Ticket.where( :group_id => group_ids ).where( self._condition( overview.condition ) ).count()

        # get meta info
        all = {
          :name => overview.name,
          :prio => overview.prio,
          :link => overview.link,
        }

        # push to result data
        result.push all.merge( { :count => count } )
      }
      return result
    end

    # get result list
    if data[:array]
      order_by = overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s
      if overview_selected.group_by && !overview_selected.group_by.empty?
        order_by = overview_selected.group_by + '_id, ' + order_by
      end
      tickets = Ticket.select( 'id' ).
      where( :group_id => group_ids ).
      where( self._condition( overview_selected.condition ) ).
      order( order_by ).
      limit( 500 )

      ticket_ids = []
      tickets.each { |ticket|
        ticket_ids.push ticket.id
      }

      tickets_count = Ticket.where( :group_id => group_ids ).
      where( self._condition( overview_selected.condition ) ).
      count()

      return {
        :ticket_list   => ticket_ids,
        :tickets_count => tickets_count,
        :overview      => overview_selected_raw,
      }
    end

    # get tickets for overview
    data[:start_page] ||= 1
    tickets = Ticket.where( :group_id => group_ids ).
    where( self._condition( overview_selected.condition ) ).
    order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s )#.
    #      limit( overview_selected.view[ data[:view_mode].to_sym ][:per_page] ).
    #      offset( overview_selected.view[ data[:view_mode].to_sym ][:per_page].to_i * ( data[:start_page].to_i - 1 ) )

    tickets_count = Ticket.where( :group_id => group_ids ).
    where( self._condition( overview_selected.condition ) ).
    count()

    return {
      :tickets       => tickets,
      :tickets_count => tickets_count,
      :overview      => overview_selected_raw,
    }

  end
  def self._condition(condition)
    sql  = ''
    bind = [nil]
    condition.each {|key, value|
      if sql != ''
        sql += ' AND '
      end
      if value.class == Array
        sql += " #{key} IN (?)"
        bind.push value
      elsif value.class == Hash || value.class == ActiveSupport::HashWithIndifferentAccess
        time = Time.now
        if value['area'] == 'minute'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60
          else
            time += value['count'].to_i * 60
          end
        elsif value['area'] == 'hour'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60
          else
            time += value['count'].to_i * 60 * 60
          end
        elsif value['area'] == 'day'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24
          else
            time += value['count'].to_i * 60 * 60 * 24
          end
        elsif value['area'] == 'month'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24 * 31
          else
            time += value['count'].to_i * 60 * 60 * 24 * 31
          end
        elsif value['area'] == 'year'
          if value['direction'] == 'last'
            time -= value['count'].to_i * 60 * 60 * 24 * 365
          else
            time += value['count'].to_i * 60 * 60 * 24 * 365
          end
        end
        if value['direction'] == 'last'
          sql += " #{key} > ?"
          bind.push time
        else
          sql += " #{key} < ?"
          bind.push time
        end
      else
        sql += " #{key} = ?"
        bind.push value
      end
    }
    bind[0] = sql
    return bind
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
