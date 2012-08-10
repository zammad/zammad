class Ticket::Article < ApplicationModel
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
      return if sender == nil
      return if sender['name'] == 'Customer'

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

        # add history record
        recipient_list = ''
        [:to, :cc].each { |key|
          if self[key] && self[key] != ''
            if recipient_list != ''
              recipient_list += ','
            end
            recipient_list += self[key]
          end
        }
        if recipient_list != ''
          History.history_create(
            :o_id                   => self.id,
            :history_type           => 'email',
            :history_object         => 'Ticket::Article',
            :related_o_id           => ticket.id,
            :related_history_object => 'Ticket',
            :value_from             => self.subject,
            :value_to               => recipient_list,
            :created_by_id          => self.created_by_id,
          )
        end

      end
    end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
  end

  class Type < ApplicationModel
  end
end
