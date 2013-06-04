require 'notification_factory'

class Observer::Ticket::Notification < ActiveRecord::Observer
  observe :ticket, 'ticket::_article'

  @@event_buffer = []

  def self.transaction

    # return if we run import mode
    return if Setting.get('import_mode')

#    puts '@@event_buffer'
#    puts @@event_buffer.inspect
    @@event_buffer.each { |event|

      # get current state of objects
      if event[:name] == 'Ticket::Article'
        article = Ticket::Article.lookup( :id => event[:id] )

        # next if article is already deleted
        next if !article

        ticket  = article.ticket
      elsif event[:name] == 'Ticket'
        ticket  = Ticket.lookup( :id => event[:id] )

        # next if ticket is already deleted
        next if !ticket

        article = ticket.articles[-1]
      else
        raise "unknown object for notification #{event[:name]}"
      end

      # send new ticket notification to agents
      if event[:name] == 'Ticket' && event[:type] == 'create'

        puts 'send new ticket notify to agent'
        send_notify(
          {
            :event     => event,
            :recipient => 'to_work_on', # group|owner|to_work_on|customer
            :subject   => 'New Ticket (#{ticket.title})',
            :body      => 'Hi #{recipient.firstname},

a new Ticket (#{ticket.title}) via i18n(#{article.ticket_article_type.name}).

Group: #{ticket.group.name}
Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
State: i18n(#{ticket.ticket_state.name})

From: #{article.from}
<snip>
#{article.body}
</snip>

#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}/#{article.id}
'
          },
          ticket,
          article
        )
      end

      # send new ticket notification to customers
      if event[:name] == 'Ticket' && event[:type] == 'create'

        # only for incoming emails
        next if article.ticket_article_type.name != 'email'

        puts 'send new ticket notify to customer'
        send_notify(
          {
            :event     => event,
            :recipient => 'customer', # group|owner|to_work_on|customer
            :subject   => 'New Ticket has been created! (#{ticket.title})',
            :body      => 'Thanks for your email. A new ticket has been created.

You wrote:
<snip>
#{article.body}
</snip>

Your email will be answered by a human ASAP

Have fun with Zammad! :-)

Your Zammad Team
'
          },
          ticket,
          article
        )
      end

      # send follow up notification
      if event[:name] == 'Ticket::Article' && event[:type] == 'create'

        # only send article notifications after init article is created (handled by ticket create event)
        next if ticket.articles.count.to_i <= 1

        puts 'send new ticket::article notify'

        if article.ticket_article_sender.name == 'Customer'
          send_notify(
            {
              :event     => event,
              :recipient => 'to_work_on', # group|owner|to_work_on|customer
              :subject   => 'Follow Up (#{ticket.title})',
              :body      => 'Hi #{recipient.firstname},

a follow Up (#{ticket.title}) via i18n(#{article.ticket_article_type.name}).

Group: #{ticket.group.name}
Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
State: i18n(#{ticket.ticket_state.name})

From: #{article.from}
<snip>
#{article.body}
</snip>

#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}/#{article.id}
'
            },
            ticket,
            article
          )
        end
        
        # send new note notification to owner
        # if agent == created.id
        if article.ticket_article_sender.name == 'Agent' && article.created_by_id != article.ticket.owner_id
          send_notify(
            {
              :event     => event,
              :recipient => 'owner', # group|owner|to_work_on
              :subject   => 'Updated (#{ticket.title})',
              :body      => 'Hi #{recipient.firstname},
              
updated (#{ticket.title}) via i18n(#{article.ticket_article_type.name}).

Group: #{ticket.group.name}
Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
State: i18n(#{ticket.ticket_state.name})

From: #{article.from}
<snip>
#{article.body}
</snip>

#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}/#{article.id}
'
            },
            ticket,
            article
          )
        end
      end
    }
    
    # reset buffer
    @@event_buffer = []
  end

  def self.send_notify(data, ticket, article)

    # find recipients
    recipients = []

    # group of agents to work on
    if data[:recipient] == 'group'
      recipients = ticket.agent_of_group()

    # owner
    elsif data[:recipient] == 'owner'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      end

    # customer
    elsif data[:recipient] == 'customer'
      if ticket.customer_id != 1
# temporarily disabled        
#        recipients.push ticket.customer
      end

    # owner or group of agents to work on
    elsif data[:recipient] == 'to_work_on'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      else
        recipients = ticket.agent_of_group()
      end
    end

    # send notifications
    recipient_list = ''
    notification_subject = ''
    recipients.each do |user|
      next if !user.email || user.email == ''

      # add recipient_list
      if recipient_list != ''
        recipient_list += ','
      end
      recipient_list += user.email.to_s

      # prepare subject & body
      notification = {}
      [:subject, :body].each { |key|
        notification[key.to_sym] = NotificationFactory.build(
          :locale  => user.locale,
          :string  => data[key.to_sym],
          :objects => {
            :ticket    => ticket,
            :article   => article,
            :recipient => user,
          }
        )
      }
      notification_subject = notification[:subject]

      # rebuild subject
      notification[:subject] = ticket.subject_build( notification[:subject] )

      # send notification
      NotificationFactory.send(
        :recipient => user,
        :subject   => notification[:subject],
        :body      => notification[:body]
      )
    end

    # add history record
    if recipient_list != ''
      History.add(
        :o_id                   => ticket.id,
        :history_type           => 'notification',
        :history_object         => 'Ticket',
        :value_from             => notification_subject,
        :value_to               => recipient_list,
        :created_by_id          => article.created_by_id || 1
      )
    end
  end

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

#    puts 'CREATED!!!!'
#    puts record.inspect
    e = {
      :name => record.class.name,
      :type => 'create',
      :data => record,
      :id   => record.id,
    }
    @@event_buffer.push e
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    puts 'before_update'
    current = record.class.find(record.id)

    # do not send anything if nothing has changed
    return if current.attributes == record.attributes
  
#    puts 'UPDATE!!!!!!!!'
#    puts 'current'
#    puts current.inspect
#    puts 'record'
#    puts record.inspect

    e = {
      :name => record.class.name,
      :type => 'update',
      :data => record,
      :id   => record.id,
    }
    @@event_buffer.push e
  end

  def after_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

#    puts 'after_update'
#    puts record.inspect
#    puts '-----'
#    puts @a.inspect
#    AuditTrail.new(record, "UPDATED")
  end
end
