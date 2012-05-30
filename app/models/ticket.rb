class Ticket < ActiveRecord::Base
  before_create :number_generate, :check_defaults
  
  belongs_to    :group
  has_many      :articles
  belongs_to    :ticket_state,    :class_name => 'Ticket::State'
  belongs_to    :ticket_priority, :class_name => 'Ticket::Priority'
  belongs_to    :owner,           :class_name => 'User'
  belongs_to    :customer,        :class_name => 'User'
  belongs_to    :created_by,      :class_name => 'User'

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

  class Number
  end

  class Flag < ActiveRecord::Base
  end

  class Priority < ActiveRecord::Base
    self.table_name = 'ticket_priorities'
  end

  class StateType < ActiveRecord::Base
  end

  class State < ActiveRecord::Base
    belongs_to :ticket_state_type, :class_name => 'Ticket::StateType'
  end

  class Article < ActiveRecord::Base
    before_create :fillup
    after_create  :attachment_check, :communicate
    belongs_to    :ticket
    belongs_to    :ticket_article_type,   :class_name => 'Ticket::Article::Type'
    belongs_to    :ticket_article_sender, :class_name => 'Ticket::Article::Sender'
    belongs_to    :created_by,            :class_name => 'User'
    
    private
      def fillup
        
        # if sender is customer, do not change anything
        sender = Ticket::Article::Sender.where( :id => self.ticket_article_sender_id ).first
        return if sender == nil || sender['name'] == 'Customer'
        
        type = Ticket::Article::Type.where( :id => self.ticket_article_type_id ).first
        ticket = Ticket.find(self.ticket_id)

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
        end
      end

    class Flag < ActiveRecord::Base
    end
  
    class Sender < ActiveRecord::Base
    end
  
    class Type < ActiveRecord::Base
    end
  end

end
