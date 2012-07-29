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

    # set state to 'merged'
    self.ticket_state_id = Ticket::State.where( :name => 'merged' ).first.id

    # rest owner
    self.owner_id = User.where(:login => '-').first.id

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

#  Ticket.overview(
#    :view            => 'some_view_url',
#    :current_user_id => 123,
#  )
  def self.overview (data)

    # build up attributes hash
    overview_selected     = nil
    overview_selected_raw = nil
    overviews             = Overview.all
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
          overview.condition[item] = data[:current_user_id]
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
    group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', [ data[:current_user_id] ] ).
      where( 'groups.active = ?', true ).
      map( &:id )

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
      tickets = Ticket.select( 'id' ).
        where( :group_id => group_ids ).
        where( overview_selected.condition ).
        order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s ).
        limit( 500 )

      tickets_count = Ticket.where( :group_id => group_ids ).
        where( overview_selected.condition ).
        count() 

      return {
        :tickets       => tickets,
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
    ticket_group_ids = []
    Group.where( :active => true ).each { |group|
      ticket_group_ids.push group.id
    }

    # get related users
    users = {}
    ticket_owner_ids = []
    Ticket.agents.each { |user|
      ticket_owner_ids.push user.id
      if !users[user.id]
        users[user.id] = User.user_data_full(user.id)
      end
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

    return users, ticket_owner_ids, ticket_group_ids, ticket_state_ids, ticket_priority_ids
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
  end

  class StateType < ApplicationModel
    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete
  end

  class State < ApplicationModel
    belongs_to :ticket_state_type, :class_name => 'Ticket::StateType'
    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete
  end

  class Article < ApplicationModel
    before_create :fillup
    after_create  :attachment_check, :communicate
    belongs_to    :ticket
    belongs_to    :ticket_article_type,   :class_name => 'Ticket::Article::Type'
    belongs_to    :ticket_article_sender, :class_name => 'Ticket::Article::Sender'
    belongs_to    :created_by,            :class_name => 'User'

    after_create  :cache_delete
    after_update  :cache_delete
    after_destroy :cache_delete

    private
      def fillup

        # if sender is customer, do not change anything
        sender = Ticket::Article::Sender.where( :id => self.ticket_article_sender_id ).first
        return if sender == nil || sender['name'] == 'Customer'

        type = Ticket::Article::Type.where( :id => self.ticket_article_type_id ).first
        ticket = Ticket.find(self.ticket_id)

        # set from if not given
        if !self.from
          user = User.find(self.created_by_id)
          self.from = "#{user.firstname} #{user.lastname}"
        end

        # set email attributes
        if type['name'] == 'email'
          
          # set subject if empty
          if !self.subject || self.subject == ''
            self.subject = ticket.title
          end
          
          # clean subject
          self.subject = ticket.subject_clean(self.subject)
          
          # generate message id
          fqdn = Setting.get('fqdn')
          self.message_id = '<' + DateTime.current.to_s(:number) + '.' + self.ticket_id.to_s + '.' + rand(999999).to_s() + '@' + fqdn + '>'

          # set sender
          if Setting.get('ticket_define_email_from') == 'AgentNameSystemAddressName'
            seperator = Setting.get('ticket_define_email_from_seperator')
            sender    = User.find(self.created_by_id)
            system_sender = Setting.get('system_sender')
            self.from = "#{sender.firstname} #{sender.lastname} #{seperator} #{system_sender}"
          else
            self.from = Setting.get('system_sender')
          end
        end
      end
      def attachment_check

        # do nothing if no attachment exists
        return 1 if self['attachments'] == nil

        # store attachments
        article_store = []
        self.attachments.each do |attachment|
          article_store.push Store.add(
            :object      => 'Ticket::Article',
            :o_id        => self.id,
            :data        => attachment.store_file.data,
            :filename    => attachment.filename,
            :preferences => attachment.preferences
          )
        end
        self.attachments = article_store
      end

      def communicate

        # if sender is customer, do not communication
        sender = Ticket::Article::Sender.where( :id => self.ticket_article_sender_id ).first
        return 1 if sender == nil || sender['name'] == 'Customer'

        type = Ticket::Article::Type.where( :id => self.ticket_article_type_id ).first
        ticket = Ticket.find(self.ticket_id)

        # if sender is agent or system

        # create tweet
        if type['name'] == 'twitter direct-message' || type['name'] == 'twitter status'
          a = Channel::Twitter2.new
          message = a.send(
            {
              :type        => type['name'],
              :to          => self.to,
              :body        => self.body,
              :in_reply_to => self.in_reply_to
            },
            Rails.application.config.channel_twitter
          )
          self.message_id = message.id
          self.save
        end

        # post facebook comment
        if type['name'] == 'facebook'
          a = Channel::Facebook.new
          a.send(
            {
              :from    => 'me@znuny.com',
              :to      => 'medenhofer',
              :body    => self.body
            }
          )
        end

        # send email
        if type['name'] == 'email'

          # build subject
          subject = ticket.subject_build(self.subject)

          # send email
          a = Channel::IMAP.new
          message = a.send(
            {
              :message_id  => self.message_id,
              :in_reply_to => self.in_reply_to,
              :from        => self.from,
              :to          => self.to,
              :cc          => self.cc,
              :subject     => subject,
              :body        => self.body,
              :attachments => self.attachments
            }
          )

          # store mail plain
          Store.add(
            :object      => 'Ticket::Article::Mail',
            :o_id        => self.id,
            :data        => message.to_s,
            :filename    => "ticket-#{ticket.number}-#{self.id}.eml",
            :preferences => {}
          )
        end
      end

    class Flag < ApplicationModel
    end

    class Sender < ApplicationModel
    end

    class Type < ApplicationModel
    end
  end

end