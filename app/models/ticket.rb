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

  before_create   :check_generate, :check_defaults
  before_update   :check_defaults
  before_destroy  :destroy_dependencies
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_destroy   :notify_clients_after_destroy

  activity_stream_support :ignore_attributes => {
    :create_article_type_id   => true,
    :create_article_sender_id => true,
    :article_count            => true,
  }

  history_support :ignore_attributes => {
    :create_article_type_id   => true,
    :create_article_sender_id => true,
    :article_count            => true,
  }

  search_index_support(
    :ignore_attributes => {
      :create_article_type_id   => true,
      :create_article_sender_id => true,
      :article_count            => true,
    },
    :keep_attributes => {
      :customer_id              => true,
      :organization_id          => true,
    },
  )

  belongs_to    :group
  has_many      :articles,              :class_name => 'Ticket::Article', :after_add => :cache_update, :after_remove => :cache_update
  belongs_to    :organization
  belongs_to    :state,                 :class_name => 'Ticket::State'
  belongs_to    :priority,              :class_name => 'Ticket::Priority'
  belongs_to    :owner,                 :class_name => 'User'
  belongs_to    :customer,              :class_name => 'User'
  belongs_to    :created_by,            :class_name => 'User'
  belongs_to    :updated_by,            :class_name => 'User'
  belongs_to    :create_article_type,   :class_name => 'Ticket::Article::Type'
  belongs_to    :create_article_sender, :class_name => 'Ticket::Article::Sender'

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
    Group.find( self.group_id ).users.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

=begin

get user access conditions

  connditions = Ticket.access_condition( User.find(1) )

returns

  result = [user1, user2, ...]

=end

  def self.access_condition(user)
    access_condition = []
    if user.is_role('Agent')
      group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', user.id ).
      where( 'groups.active = ?', true ).
      map( &:id )
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
      :ticket_id  => self.id,
      :type_id    => Ticket::Article::Type.lookup( :name => 'note' ).id,
      :sender_id  => Ticket::Article::Sender.lookup( :name => 'Agent' ).id,
      :body       => 'merged',
      :internal   => false
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
    self.state_id = Ticket::State.lookup( :name => 'merged' ).id

    # rest owner
    self.owner_id = User.where( :login => '-' ).first.id

    # save ticket
    self.save
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
    if self.customer_id
      customer = User.find( self.customer_id )
      if self.organization_id != customer.organization_id
        self.organization_id = customer.organization_id
      end
    end
  end

  def destroy_dependencies

    # delete articles
    self.articles.destroy_all
  end

end
