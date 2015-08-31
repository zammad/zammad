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

  before_create   :check_generate, :check_defaults, :check_title
  before_update   :check_defaults, :check_title, :reset_pending_time
  before_destroy  :destroy_dependencies

  notify_clients_support

  latest_change_support

  activity_stream_support ignore_attributes: {
    create_article_type_id: true,
    create_article_sender_id: true,
    article_count: true,
  }

  history_support ignore_attributes: {
    create_article_type_id: true,
    create_article_sender_id: true,
    article_count: true,
  }

  search_index_support(
    ignore_attributes: {
      create_article_type_id: true,
      create_article_sender_id: true,
      article_count: true,
    },
    keep_attributes: {
      customer_id: true,
      organization_id: true,
    },
  )

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
    Group.find( group_id ).users.where( active: true ).joins(:roles).where( 'roles.name' => Z_ROLENAME_AGENT, 'roles.active' => true ).uniq()
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
      if !user.organization || ( !user.organization.shared || user.organization.shared == false )
        access_condition = [ 'customer_id = ?', user.id ]
      else
        access_condition = [ '( customer_id = ? OR organization_id = ? )', user.id, user.organization.id ]
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
    .where.not(next_state_id: nil) # rubocop:disable Style/MultilineOperationIndentation

    return [] if !ticket_states

    next_state_map = {}
    ticket_states.each { |state|
      next_state_map[state.id] = state.next_state_id
    }

    tickets = where(
      state_id: next_state_map.keys,
    )
    .where( 'pending_time <= ?', Time.zone.now ) # rubocop:disable Style/MultilineOperationIndentation

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
    :ticket_id => 123,
    :user_id   => 123,
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

know if online notifcation should be shown as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state

returns

  result = true # or false

=end

  def online_notification_seen_state
    state      = Ticket::State.lookup( id: state_id )
    state_type = Ticket::StateType.lookup( id: state.state_type_id )

    # set all to seen if pending action state is a closed or merged state
    if state_type.name == 'pending action' && state.next_state_id
      state      = Ticket::State.lookup( id: state.next_state_id )
      state_type = Ticket::StateType.lookup( id: state.state_type_id )
    end

    # set all to seen if new state is pending reminder state
    return true if state_type.name == 'pending reminder'

    # set all to seen if new state is a closed or merged state
    return true if state_type.name == 'closed'
    return true if state_type.name == 'merged'
    false
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
