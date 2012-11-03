class Ticket < ApplicationModel
  before_create   :number_generate, :check_defaults
  before_destroy  :destroy_dependencies
  
  belongs_to    :group
  has_many      :articles,                                          :after_add => :cache_update, :after_remove => :cache_update
  belongs_to    :ticket_state,    :class_name => 'Ticket::State'
  belongs_to    :ticket_priority, :class_name => 'Ticket::Priority'
  belongs_to    :owner,           :class_name => 'User'
  belongs_to    :customer,        :class_name => 'User'
  belongs_to    :created_by,      :class_name => 'User'

  after_create  :cache_delete
  after_update  :cache_delete
  after_destroy :cache_delete

  @@number_adapter = nil

  def number_adapter
    return @@number_adapter
  end

  def number_adapter=(adapter_name)  
    return @@number_adapter if @@number_adapter
    case adapter_name  
    when Symbol, String  
      require "ticket/number/#{adapter_name.to_s.downcase}"  
      @@number_adapter = Ticket::Number.const_get("#{adapter_name.to_s.capitalize}")
    else  
      raise "Missing number_adapter #{adapter_name}"  
    end  
  end  
  
  def self.number_check (string)
    Ticket.new.number_adapter = Setting.get('ticket_number')
    @@number_adapter.number_check_item(string)
  end

  def agent_of_group
    Group.find(self.group_id).users.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

  def self.agents
    User.where( :active => true ).joins(:roles).where( 'roles.name' => 'Agent', 'roles.active' => true ).uniq()
  end

  def merge_to(data)
    
    # update articles
    Ticket::Article.where( :ticket_id => self.id ).update_all( ['ticket_id = ?', data[:ticket_id] ] )
    
    # update history
    
    # create new merge article
    Ticket::Article.create(
      :created_by_id            => data[:created_by_id],
      :ticket_id                => self.id, 
      :ticket_article_type_id   => Ticket::Article::Type.where( :name => 'note' ).first.id,
      :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Agent' ).first.id,
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
    self.ticket_state_id = Ticket::State.where( :name => 'merged' ).first.id

    # rest owner
    self.owner_id = User.where( :login => '-' ).first.id

    # save ticket
    self.save
  end

#  def self.agent
#    Role.where( :name => ['Agent'], :active => true ).first.users.where( :active => true ).uniq()
#  end

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

#  ticket.permission(
#    :current_user => 123
#  )
  def permission (data)

    # check customer
    if data[:current_user].is_role('Customer')
      return true if self.customer_id == data[:current_user].id
      return false
    end

    # check agent
    return true if self.owner_id == data[:current_user].id
    data[:current_user].groups.each {|group|
      return true if self.group.id == group.id
    }
    return false
  end

#  Ticket.overview_list(
#    :current_user => 123,
#  )
  def self.overview_list (data)
    # get user role
    if data[:current_user].is_role('Customer')
      role = data[:current_user].is_role( 'Customer' )
    else
      role = data[:current_user].is_role( 'Agent' )
    end
    Overview.where( :role_id => role.id )
  end

#  Ticket.overview(
#    :view         => 'some_view_url',
#    :current_user => OBJECT,
#  )
  def self.overview (data)

    # get user role
    if data[:current_user].is_role('Customer')
      role = data[:current_user].is_role( 'Customer' )
    else
      role = data[:current_user].is_role( 'Agent' )
    end

    # build up attributes hash
    overview_selected     = nil
    overview_selected_raw = nil
    overviews             = Overview.where( :role_id => role.id )
    overviews.each { |overview|

      # for cleanup reasons, remove me later!
      overview.condition.each { |item, value |
        if item == 'owner_id' && overview.condition[item] != 1
          overview.condition[item] = 'current_user.id'
        end
      }

      # remember selected view
      if data[:view] && data[:view] == overview.meta[:url]
        overview_selected     = overview
        overview_selected_raw = Marshal.load( Marshal.dump(overview.attributes) )
      end

      # replace 'current_user.id' with current_user.id
      overview.condition.each { |item, value |
        if value == 'current_user.id'
          overview.condition[item] = data[:current_user].id
        end
      }
    }

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
        count = Ticket.where( :group_id => group_ids ).where( overview.condition ).count()

        # get meta info
        all = overview.meta

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
        where( overview_selected.condition ).
        order( order_by ).
        limit( 500 )

      ticket_ids = []
      tickets.each { |ticket|
        ticket_ids.push ticket.id
      }

      tickets_count = Ticket.where( :group_id => group_ids ).
        where( overview_selected.condition ).
        count()

      return {
        :tickets       => ticket_ids,
        :tickets_count => tickets_count,
        :overview      => overview_selected_raw,
      }
    end

    # get tickets for overview
    data[:start_page] ||= 1
    tickets = Ticket.where( :group_id => group_ids ).
      where( overview_selected.condition ).
      order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s ).
      limit( overview_selected.view[ data[:view_mode].to_sym ][:per_page] ).
      offset( overview_selected.view[ data[:view_mode].to_sym ][:per_page].to_i * ( data[:start_page].to_i - 1 ) )

    tickets_count = Ticket.where( :group_id => group_ids ).
      where( overview_selected.condition ).
      count()

    return {
      :tickets       => tickets,
      :tickets_count => tickets_count,
      :overview      => overview_selected_raw,
    }

  end

#  data = Ticket.full_data(123)
  def self.full_data(ticket_id)
    cache = self.cache_get(ticket_id)
    return cache if cache

    ticket = Ticket.find(ticket_id).attributes
    self.cache_set( ticket_id, ticket )
    return ticket
  end

#  Ticket.create_attributes(
#    :current_user_id => 123,
#  )
  def self.create_attributes (data)

    # get groups
    group_ids = []
    Group.where( :active => true ).each { |group|
      group_ids.push group.id
    }

    # get related users
#    users = {}
    user_ids = []
    agents = {}
    Ticket.agents.each { |user|
      agents[ user.id ] = 1
      user_ids.push user.id
    }
    groups_users = {}
    group_ids.each {|group_id|
        groups_users[ group_id ] = []
        Group.find(group_id).users.each {|user|
            next if !agents[ user.id ]
            groups_users[ group_id ].push user.id
#            if !users[user.id]
#              users[user.id] = User.user_data_full(user.id)
#            end
        }
    }

    # get states
    ticket_state_ids = []
    Ticket::State.where( :active => true ).each { |state|
      ticket_state_ids.push state.id
    }

    # get priorities
    ticket_priority_ids = []
    Ticket::Priority.where( :active => true ).each { |priority|
      ticket_priority_ids.push priority.id
    }

    return {
#      :users              => users,
      :owner_id           => user_ids,
      :group_id__owner_id => groups_users,
      :group_id           => group_ids,
      :ticket_state_id    => ticket_state_ids,
      :ticket_priority_id => ticket_priority_ids,
    }
  end

  private
    def number_generate
      Ticket.new.number_adapter = Setting.get('ticket_number')
      (1..15_000).each do |i|
        number = @@number_adapter.number_generate_item()
        ticket = Ticket.where( :number => number ).first
        if ticket != nil
          number = @@number_adapter.number_generate_item()
        else
          self.number = number
          return number
        end
      end
    end
    def check_defaults
      if !self.owner_id then
        self.owner_id = 1
      end
    end
    def destroy_dependencies

      # delete history
      History.history_destroy( 'Ticket', self.id )

      # delete articles
      self.articles.destroy_all
    end

  class Number
  end

  class Flag < ApplicationModel
  end

  class Priority < ApplicationModel
    self.table_name = 'ticket_priorities'
    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete
    validates     :name, :presence => true
  end

  class StateType < ApplicationModel
    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete
    validates     :name, :presence => true
  end

  class State < ApplicationModel
    belongs_to :ticket_state_type, :class_name => 'Ticket::StateType'
    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete
    validates     :name, :presence => true
  end
end