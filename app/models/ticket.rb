# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Ticket < ApplicationModel
  include Ticket::Escalation
  include Ticket::Subject
  include Ticket::Permission
  load 'ticket/assets.rb'
  include Ticket::Assets
  load 'ticket/history_log.rb'
  include Ticket::HistoryLog
  load 'ticket/activity_stream_log.rb'
  include Ticket::ActivityStreamLog
  load 'ticket/search_index.rb'
  include Ticket::SearchIndex
  extend Ticket::Search

  store           :preferences
  before_create   :check_generate, :check_defaults, :check_title
  before_update   :check_defaults, :check_title, :reset_pending_time
  before_destroy  :destroy_dependencies

  notify_clients_support

  latest_change_support

  activity_stream_support ignore_attributes: {
    create_article_type_id: true,
    create_article_sender_id: true,
    article_count: true,
    first_response: true,
    first_response_escal_date: true,
    first_response_sla_time: true,
    first_response_in_min: true,
    first_response_diff_in_min: true,
    close_time: true,
    close_time_escal_date: true,
    close_time_sla_time: true,
    close_time_in_min: true,
    close_time_diff_in_min: true,
    update_time_escal_date: true,
    update_time_sla_time: true,
    update_time_in_min: true,
    update_time_diff_in_min: true,
    last_contact: true,
    last_contact_agent: true,
    last_contact_customer: true,
  }

  history_support ignore_attributes: {
    create_article_type_id: true,
    create_article_sender_id: true,
    article_count: true,
  }

  search_index_support

  belongs_to    :group
  has_many      :articles,              class_name: 'Ticket::Article', after_add: :cache_update, after_remove: :cache_update
  belongs_to    :organization
  belongs_to    :state,                 class_name: 'Ticket::State'
  belongs_to    :priority,              class_name: 'Ticket::Priority'
  belongs_to    :owner,                 class_name: 'User'
  belongs_to    :customer,              class_name: 'User'
  belongs_to    :created_by,            class_name: 'User'
  belongs_to    :updated_by,            class_name: 'User'
  belongs_to    :create_article_type,   class_name: 'Ticket::Article::Type'
  belongs_to    :create_article_sender, class_name: 'Ticket::Article::Sender'

  self.inheritance_column = nil

  attr_accessor :callback_loop

=begin

list of agents in group of ticket

  ticket = Ticket.find(123)
  result = ticket.agent_of_group

returns

  result = [user1, user2, ...]

=end

  def agent_of_group
    Group.find(group_id)
         .users.where(active: true)
         .joins(:roles)
         .where('roles.name' => Z_ROLENAME_AGENT, 'roles.active' => true)
         .order('users.login')
         .uniq()
  end

=begin

get user access conditions

  conditions = Ticket.access_condition( User.find(1) )

returns

  result = [user1, user2, ...]

=end

  def self.access_condition(user)
    access_condition = []
    if user.role?(Z_ROLENAME_AGENT)
      group_ids = Group.select( 'groups.id' ).joins(:users)
                       .where( 'groups_users.user_id = ?', user.id )
                       .where( 'groups.active = ?', true )
                       .map( &:id )
      access_condition = [ 'group_id IN (?)', group_ids ]
    else
      access_condition = if !user.organization || ( !user.organization.shared || user.organization.shared == false )
                           [ 'tickets.customer_id = ?', user.id ]
                         else
                           [ '( tickets.customer_id = ? OR tickets.organization_id = ? )', user.id, user.organization.id ]
                         end
    end
    access_condition
  end

=begin

processes tickets which have reached their pending time and sets next state_id

  processed_tickets = Ticket.process_pending()

returns

  processed_tickets = [<Ticket>, ...]

=end

  def self.process_pending

    ticket_states = Ticket::State.where(
      state_type_id: Ticket::StateType.find_by( name: 'pending action' ),
    )
                                 .where.not(next_state_id: nil)

    return [] if !ticket_states

    next_state_map = {}
    ticket_states.each { |state|
      next_state_map[state.id] = state.next_state_id
    }

    tickets = where(
      state_id: next_state_map.keys,
    )
              .where( 'pending_time <= ?', Time.zone.now )

    return [] if !tickets

    result = []
    tickets.each { |ticket|
      ticket.state_id      = next_state_map[ticket.state_id]
      ticket.updated_at    = Time.zone.now
      ticket.updated_by_id = 1
      ticket.save!

      result.push ticket
    }

    # we do not have an destructor at this point, so we need to
    # execute ticket events manually
    Observer::Ticket::Notification.transaction

    result
  end

=begin

merge tickets

  ticket = Ticket.find(123)
  result = ticket.merge_to(
    ticket_id: 123,
    user_id:   123,
  )

returns

  result = true|false

=end

  def merge_to(data)

    # update articles
    Ticket::Article.where( ticket_id: id ).each(&:touch)

    # quiet update of reassign of articles
    Ticket::Article.where( ticket_id: id ).update_all( ['ticket_id = ?', data[:ticket_id] ] )

    # touch new ticket (to broadcast change)
    Ticket.find( data[:ticket_id] ).touch

    # update history

    # create new merge article
    Ticket::Article.create(
      ticket_id: id,
      type_id: Ticket::Article::Type.lookup( name: 'note' ).id,
      sender_id: Ticket::Article::Sender.lookup( name: Z_ROLENAME_AGENT ).id,
      body: 'merged',
      internal: false,
      created_by_id: data[:user_id],
      updated_by_id: data[:user_id],
    )

    # add history to both

    # link tickets
    Link.add(
      link_type: 'parent',
      link_object_source: 'Ticket',
      link_object_source_value: data[:ticket_id],
      link_object_target: 'Ticket',
      link_object_target_value: id
    )

    # set state to 'merged'
    self.state_id = Ticket::State.lookup( name: 'merged' ).id

    # rest owner
    self.owner_id = User.find_by( login: '-' ).id

    # save ticket
    save
  end

=begin

check if online notifcation should be shown in general as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state(user_id_check)

returns

  result = true # or false

check if online notifcation should be shown for this user as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state(check_user_id)

returns

  result = true # or false

=end

  def online_notification_seen_state(user_id_check = nil)
    state      = Ticket::State.lookup( id: state_id )
    state_type = Ticket::StateType.lookup( id: state.state_type_id )

    # set all to seen if pending action state is a closed or merged state
    if state_type.name == 'pending action' && state.next_state_id
      state      = Ticket::State.lookup( id: state.next_state_id )
      state_type = Ticket::StateType.lookup( id: state.state_type_id )
    end

    # set all to seen if new state is pending reminder state
    if state_type.name == 'pending reminder'
      if user_id_check
        return false if owner_id == 1
        return false if updated_by_id != owner_id && user_id_check == owner_id
        return true
      end
      return true
    end

    # set all to seen if new state is a closed or merged state
    return true if state_type.name == 'closed'
    return true if state_type.name == 'merged'
    false
  end

=begin

get count of tickets and tickets which match on selector

  ticket_count, tickets = Ticket.selectors(params[:condition], limit, current_user)

=end

  def self.selectors(selectors, limit = 10, current_user = nil)
    fail 'no selectors given' if !selectors
    query, bind_params, tables = selector2sql(selectors, current_user)
    return [] if !query

    if !current_user
      ticket_count = Ticket.where(query, *bind_params).joins(tables).count
      tickets = Ticket.where(query, *bind_params).joins(tables).limit(limit)
      return [ticket_count, tickets]
    end

    access_condition = Ticket.access_condition(current_user)
    ticket_count = Ticket.where(access_condition).where(query, *bind_params).joins(tables).count
    tickets = Ticket.where(access_condition).where(query, *bind_params).joins(tables).limit(limit)
    [ticket_count, tickets]
  end

=begin

generate condition query to search for tickets based on condition

  query_condition, bind_condition = selector2sql(params[:condition], current_user)

condition example

  {
    'ticket.state_id' => {
      operator: 'is',
      value: [1,2,5]
    },
    'ticket.created_at' => {
      operator: 'after (absolute)', # after,before
      value: '2015-10-17T06:00:00.000Z',
    },
    'ticket.created_at' => {
      operator: 'within next (relative)', # before,within,in,after
      range: 'day', # minute|hour|day|month|year
      value: '25',
    },
    'ticket.owner_id' => {
      operator: 'is', # is not
      pre_condition: 'current_user.id',
    },
    'ticket.owner_id' => {
      operator: 'is', # is not
      pre_condition: 'specific',
      value: 4711,
    },
  }

=end

  def self.selector2sql(selectors, current_user = nil)
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end
    return if !selectors

    # remember query and bind params
    query = ''
    bind_params = []
    like = Rails.application.config.db_like

    # get tables to join
    tables = ''
    selectors.each {|attribute, selector|
      selector = attribute.split(/\./)
      next if !selector[1]
      next if selector[0] == 'ticket'
      next if tables.include?(selector[0])
      if query != ''
        query += ' AND '
      end
      if selector[0] == 'customer'
        tables += ', users customers'
        query += 'tickets.customer_id = customers.id'
      elsif selector[0] == 'organization'
        tables += ', organizations'
        query += 'tickets.organization_id = organizations.id'
      elsif selector[0] == 'owner'
        tables += ', users owners'
        query += 'tickets.owner_id = owners.id'
      else
        fail "invalid selector #{attribute.inspect}->#{selector.inspect}"
      end
    }

    # add conditions
    selectors.each {|attribute, selector_raw|

      # validation
      fail "Invalid selector #{selector_raw.inspect}" if !selector_raw
      fail "Invalid selector #{selector_raw.inspect}" if !selector_raw.respond_to?(:key?)
      selector = selector_raw.stringify_keys
      fail "Invalid selector, operator missing #{selector.inspect}" if !selector['operator']

      # validate value / allow empty but only if pre_condition eyists
      if selector['value'].nil? || (selector['value'].respond_to?(:empty?) && selector['value'].empty?)
        return nil if selector['pre_condition'].nil? || (selector['pre_condition'].respond_to?(:empty?) && selector['pre_condition'].empty?)
      end

      # validate pre_condition values
      return nil if selector['pre_condition'] && selector['pre_condition'] !~ /^(set|current_user\.|specific)/

      # get attributes
      attributes = attribute.split(/\./)
      attribute = "#{attributes[0]}s.#{attributes[1]}"

      if query != ''
        query += ' AND '
      end

      if selector['operator'] == 'is'
        if selector['pre_condition'] == 'set'
          if attributes[1] =~ /^(created_by|updated_by|owner|customer|user)_id/
            query += "#{attribute} NOT IN (?)"
            bind_params.push 1
          else
            query += "#{attribute} IS NOT NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          fail "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id
          query += "#{attribute} IN (?)"
          bind_params.push current_user_id
        elsif selector['pre_condition'] == 'current_user.organization_id'
          fail "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id
          query += "#{attribute} IN (?)"
          user = User.lookup(id: current_user_id)
          bind_params.push user.organization_id
        else
          query += "#{attribute} IN (?)"
          bind_params.push selector['value']
        end
      elsif selector['operator'] == 'is not'
        if selector['pre_condition'] == 'set'
          if attributes[1] =~ /^(created_by|updated_by|owner|customer|user)_id/
            query += "#{attribute} IN (?)"
            bind_params.push 1
          else
            query += "#{attribute} IS NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          query += "#{attribute} NOT IN (?)"
          bind_params.push current_user_id
        elsif selector['pre_condition'] == 'current_user.organization_id'
          query += "#{attribute} NOT IN (?)"
          user = User.lookup(id: current_user_id)
          bind_params.push user.organization_id
        else
          query += "#{attribute} NOT IN (?)"
          bind_params.push selector['value']
        end
      elsif selector['operator'] == 'contains'
        query += "#{attribute} #{like} (?)"
        value = "%#{selector['value']}%"
        bind_params.push value
      elsif selector['operator'] == 'contains not'
        query += "#{attribute} NOT #{like} (?)"
        value = "%#{selector['value']}%"
        bind_params.push value
      elsif selector['operator'] == 'before (absolute)'
        query += "#{attribute} <= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'after (absolute)'
        query += "#{attribute} >= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'within last (relative)'
        query += "#{attribute} >= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now - selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now - selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now - selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now - selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now - selector['value'].to_i.years
        else
          fail "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'within next (relative)'
        query += "#{attribute} <= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now + selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now + selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now + selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now + selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now + selector['value'].to_i.years
        else
          fail "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'before (relative)'
        query += "#{attribute} <= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now - selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now - selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now - selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now - selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now - selector['value'].to_i.years
        else
          fail "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'after (relative)'
        query += "#{attribute} >= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now + selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now + selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now + selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now + selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now + selector['value'].to_i.years
        else
          fail "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      else
        fail "Invalid operator '#{selector['operator']}' for '#{selector['value'].inspect}'"
      end
    }
    [query, bind_params, tables]
  end

=begin

get all email references headers of a ticket, to exclude some, parse it as array into method

  references = ticket.get_references

result

  ['message-id-1234', 'message-id-5678']

ignore references header(s)

  references = ticket.get_references(['message-id-5678'])

result

  ['message-id-1234']

=end

  def get_references(ignore = [])
    references = []
    Ticket::Article.select('in_reply_to, message_id').where(ticket_id: id).each {|article|
      if !article.in_reply_to.empty?
        references.push article.in_reply_to
      end
      next if !article.message_id
      next if article.message_id.empty?
      references.push article.message_id
    }
    ignore.each {|item|
      references.delete(item)
    }
    references
  end

  private

  def check_generate
    return if number
    self.number = Ticket::Number.generate
  end

  def check_title
    return if !title
    title.gsub!(/\s|\t|\r/, ' ')
  end

  def check_defaults
    if !owner_id
      self.owner_id = 1
    end

    return if !customer_id

    customer = User.find( customer_id )
    return if organization_id == customer.organization_id

    self.organization_id = customer.organization_id
  end

  def reset_pending_time

    # ignore if no state has changed
    return if !changes['state_id']

    # check if new state isn't pending*
    current_state      = Ticket::State.lookup( id: state_id )
    current_state_type = Ticket::StateType.lookup( id: current_state.state_type_id )

    # in case, set pending_time to nil
    return if current_state_type.name =~ /^pending/i

    self.pending_time = nil
  end

  def destroy_dependencies

    # delete articles
    articles.destroy_all

    # destroy online notifications
    OnlineNotification.remove( self.class.to_s, id )
  end

end
