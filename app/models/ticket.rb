class Ticket < ApplicationModel
  before_create   :number_generate, :check_defaults
  before_update   :check_defaults
  before_destroy  :destroy_dependencies

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

  def self.number_check (string)
    self.number_adapter.number_check_item(string)
  end

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

  def merge_to(data)

    # update articles
    Ticket::Article.where( :ticket_id => self.id ).update_all( ['ticket_id = ?', data[:ticket_id] ] )

    # update history

    # create new merge article
    Ticket::Article.create(
      :created_by_id            => data[:created_by_id],
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

#  Ticket.overview(
#    :view         => 'some_view_url',
#    :current_user => OBJECT,
#  )
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
        count = Ticket.where( :group_id => group_ids ).where( overview.condition ).count()

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
        :ticket_list   => ticket_ids,
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

  def self.number_adapter

    # load backend based on config
    adapter_name = Setting.get('ticket_number')
    adapter = nil
    case adapter_name
    when Symbol, String
      require "ticket/number/#{adapter_name.to_s.downcase}"
      adapter = Ticket::Number.const_get("#{adapter_name.to_s.capitalize}")
    else  
      raise "Missing number_adapter '#{adapter_name}'"
    end
    return adapter
  end

  def self.escalation_calculation_rebuild
    ticket_state_list_open   = Ticket::State.where(
      :state_type_id => Ticket::StateType.where(
        :name => ['new','open', 'pending reminder', 'pending action']
      )
    )
    tickets = Ticket.where( :ticket_state_id => ticket_state_list_open )
    tickets.each {|ticket|
      ticket.escalation_calculation
    }
  end

  def escalation_calculation

    # set escalation off if ticket is already closed
    ticket_state      = Ticket::State.lookup( :id => self.ticket_state_id )
    ticket_state_type = Ticket::StateType.lookup( :id => ticket_state.state_type_id )
    ignore_escalation = ['removed', 'closed', 'merged', 'pending action']
    if ignore_escalation.include?(ticket_state_type.name)
      self.escalation_time            = nil
#      self.first_response_escal_date  = nil
#      self.close_time_escal_date      = nil
      self.save
      return true
    end

    # get sla
    sla_selected = nil
    Sla.where( :active => true ).each {|sla|
      if sla.condition
        puts sla.condition.inspect
        hit = false
        map = [
          [ 'tickets.ticket_priority_id', 'ticket_priority_id' ],
          [ 'tickets.group_id', 'group_id' ]
        ]
        map.each {|item|
          if sla.condition[ item[0] ]
            if sla.condition[ item[0] ].class == String
              sla.condition[ item[0] ] = [ sla.condition[ item[0] ] ]
            end
            if sla.condition[ item[0] ].include?( self[ item[1] ].to_s )
              hit = true
            else
              hit = false
            end
          end
        }
        if hit
          sla_selected = sla
        end
      end
    }

    # reset escalation if no sla is set
    if !sla_selected
      self.escalation_time            = nil
#      self.first_response_escal_date  = nil
#      self.close_time_escal_date      = nil
      self.save
      return true
    end

    # get calendar settings
    BusinessTime::Config.beginning_of_workday = sla_selected.data['beginning_of_workday']
    BusinessTime::Config.end_of_workday       = sla_selected.data['end_of_workday']
    days = []
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].each {|day|
      if sla_selected.data[day]
        days.push day.downcase.to_sym
      end
    }
    BusinessTime::Config.work_week = days
#    puts sla_selected.inspect
#    puts days.inspect

    self.escalation_time            = nil
    self.first_response_escal_date  = nil
    self.close_time_escal_date      = nil

    # first response
    if sla_selected.first_response_time
      created_at = Time.parse(self.created_at.to_s)
      self.first_response_escal_date = (sla_selected.first_response_time / 60).round.business_hour.after( created_at )

      # set ticket escalation
      if !self.first_response && (!self.escalation_time || self.escalation_time > self.first_response_escal_date)
        self.escalation_time = self.first_response_escal_date
      end
    end

    if self.first_response && !self.first_response_in_min
      created_at        = Time.parse(self.created_at.to_s)
      first_response_at = Time.parse(self.first_response.to_s)
      diff = created_at.business_time_until(first_response_at) / 60
      self.first_response_in_min = diff.round
    end

#    # update time
#    if sla_selected.close_time
#      created_at = Time.parse(self.created_at.to_s)
#      self.close_time_escal_date = (sla_selected.close_time / 60).round.business_hour.after( created_at )
#    end

    # close time
    if sla_selected.close_time
      created_at = Time.parse(self.created_at.to_s)
      self.close_time_escal_date = (sla_selected.close_time / 60).round.business_hour.after( created_at )

      # set ticket escalation
      if !self.close_time && (!self.escalation_time || self.escalation_time > self.close_time_escal_date)
        self.escalation_time = self.close_time_escal_date
      end
    end

    if self.close_time && !self.close_time_in_min
      created_at  = Time.parse(self.created_at.to_s)
      closed_at   = Time.parse(self.close_time.to_s)
      diff = created_at.business_time_until(closed_at) / 60
      self.close_time_in_min = diff.round
    end

    self.save
  end

  private

    def number_generate
      return if self.number

      # generate number
      (1..25_000).each do |i|
        number = Ticket.number_adapter.number_generate_item()
        ticket = Ticket.where( :number => number ).first
        if ticket != nil
          number = Ticket.number_adapter.number_generate_item()
        else
          self.number = number
          return number
        end
      end
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
    validates     :name, :presence => true
  end

  class StateType < ApplicationModel
    has_many      :states,            :class_name => 'Ticket::State'
    validates     :name, :presence => true
  end

  class State < ApplicationModel
    belongs_to    :state_type,        :class_name => 'Ticket::StateType'
    validates     :name, :presence => true
  end
end