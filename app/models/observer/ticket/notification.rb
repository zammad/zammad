# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'event_buffer'
require 'notification_factory'

class Observer::Ticket::Notification < ActiveRecord::Observer
  observe :ticket, 'ticket::_article'

  def self.transaction

    # return if we run import mode
    return if Setting.get('import_mode')

    # get buffer
    list = EventBuffer.list

    # reset buffer
    EventBuffer.reset

    list.each { |event|

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
        next if !article
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

            a new Ticket (#{ticket.title}) via i18n(#{article.type.name}).

            Group: #{ticket.group.name}
            Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
            State: i18n(#{ticket.state.name})

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
        next if article.type.name != 'email'

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

        if article.sender.name == 'Customer'
          send_notify(
            {
              :event     => event,
              :recipient => 'to_work_on', # group|owner|to_work_on|customer
              :subject   => 'Follow Up (#{ticket.title})',
              :body      => 'Hi #{recipient.firstname},

              a follow Up (#{ticket.title}) via i18n(#{article.type.name}).

              Group: #{ticket.group.name}
              Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
              State: i18n(#{ticket.state.name})

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
        if article.sender.name == 'Agent' && article.created_by_id != article.ticket.owner_id
          send_notify(
            {
              :event     => event,
              :recipient => 'owner', # group|owner|to_work_on
              :subject   => 'Updated (#{ticket.title})',
              :body      => 'Hi #{recipient.firstname},

              updated (#{ticket.title}) via i18n(#{article.type.name}).

              Group: #{ticket.group.name}
              Owner: #{ticket.owner.firstname} #{ticket.owner.lastname}
              State: i18n(#{ticket.state.name})

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
  end

  def self.send_notify(data, ticket, article)

    # send background job
    params = {
      :ticket_id  => ticket.id,
      :article_id => article.id,
      :data       => data,
    }
    Delayed::Job.enqueue( Observer::Ticket::Notification::BackgroundJob.new( params ) )
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
    EventBuffer.add(e)
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    #puts 'before_update'
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
    EventBuffer.add(e)
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
