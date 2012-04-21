class Ticket::Observer::Notification < ActiveRecord::Observer
  observe :ticket, 'ticket::_article'

  @@event_buffer = []

  def self.transaction
    
#    puts '@@event_buffer'
#    puts @@event_buffer.inspect
    @@event_buffer.each { |event|
      if event[:name] == 'Ticket' && event[:type] == 'create'
        ticket = Ticket.find( event[:id] )

        # send new ticket notification to agents
        puts 'send new ticket notify to agent'
        send_notify(
          {
            :event     => event,
            :recipient => 'to_work_on', # group|owner|to_work_on|customer
            :subject   => 'New Ticket (#{ticket.title})',
            :body      => 'Hi #{recipient.firstname},

a new Ticket (#{ticket.title}) in Group #{ticket.group.name}
            
From: #{ticket.articles[-1].from}
<snip>
#{ticket.articles[-1].body}
</snip>

#{config.http_type}://#{config.fqdn}/ticket/zoom/#{ticket.id}/#{ticket.articles[-1].id}
'
          },
          ticket,
          nil
        )

        # send new ticket notification to customers
        puts 'send new ticket notify to customer'
        send_notify(
          {
            :event     => event,
            :recipient => 'customer', # group|owner|to_work_on|customer
            :subject   => 'New Ticket has been created! (#{ticket.title})',
            :body      => 'Thanks for your email. A new ticket has been created.

You wrote:
<snip>
#{ticket.articles[-1].body}
</snip>

Your email will be answered by a human ASAP

Have fun with Zammad! :-)

Your Zammad Team
'
          },
          ticket,
          nil
        )
      end

      # send follow up notification
      if event[:name] == 'Ticket::Article' && event[:type] == 'create'
        article = Ticket::Article.find( event[:id] )
        ticket  = article.ticket

        # only send article notifications after init article is created (handled by ticket create event)
        next if ticket.articles.count >= 1

        puts 'send new ticket::article notify'

        if article.ticket_article_sender.name == 'Customer'
          send_notify(
            {
              :event     => event,
              :recipient => 'to_work_on', # group|owner|to_work_on|customer
              :subject   => 'Follow Up (#{ticket.title})',
              :body      => 'Hi #{recipient.firstname},

a follow Up (#{ticket.title}) in Group #{ticket.group.name}
            
From: #{ticket.articles[-1].from}
<snip>
#{ticket.articles[-1].body}
</snip>

#{config.http_type}://#{config.fqdn}/ticket/zoom/#{ticket.id}/#{ticket.articles[-1].id}
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
              :subject   => 'Update (#{ticket.title})',
              :body      => 'Update (#{ticket.title}) in Group #{ticket.group.name}
            
From: #{ticket.articles[-1].from}

<snip>
#{ticket.articles[-1].body}
</snip>

#{config.http_type}://#{config.fqdn}/ticket/zoom/#{ticket.id}/#{ticket.articles[-1].id}
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
    recipients.each do |user|
      next if !user.email || user.email == ''

      # prepare subject & body
      notification = {}
      [:subject, :body].each { |key|
        notification[key.to_sym] = NotificationFactory.build(
          :string  => data[key.to_sym],
          :objects => {
            :ticket    => ticket,
            :article   => article,
            :recipient => user,
          }
        )
      }

      # rebuild subject
      notification[:subject] = ticket.subject_build( notification[:subject] )

      # send notification
      NotificationFactory.send(
        :recipient => user,
        :subject   => notification[:subject],
        :body      => notification[:body]
      )
    end
  end

  def after_create(record)
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
#    puts 'after_update'
#    puts record.inspect
#    puts '-----'
#    puts @a.inspect
#    AuditTrail.new(record, "UPDATED")
  end
end