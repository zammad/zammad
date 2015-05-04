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

    # get uniq objects
    listObjects = get_uniq_changes(list)
    listObjects.each {|ticket_id, item|

      # send background job
      Delayed::Job.enqueue( Observer::Ticket::Notification::BackgroundJob.new( item ) )
    }
  end

=begin

  result = get_uniq_changes(events)

  result = {
    :1 => {
      :type       => 'create',
      :ticket_id  => 123,
      :article_id => 123,
    },
    :9 = {
      :type      => 'update',
      :ticket_id => 123,
      :changes   => {
        :attribute1 => [before,now],
        :attribute2 => [before,now],
      }
    },
  }

=end

  def self.get_uniq_changes(events)
    listObjects = {}
    events.each { |event|

      # get current state of objects
      if event[:name] == 'Ticket::Article'
        article = Ticket::Article.lookup( id: event[:id] )

        # next if article is already deleted
        next if !article

        ticket = article.ticket
        if !listObjects[ticket.id]
          listObjects[ticket.id] = {}
        end
        listObjects[ticket.id][:article_id] = article.id
        listObjects[ticket.id][:ticket_id]  = ticket.id

        if !listObjects[ticket.id][:type]
          listObjects[ticket.id][:type] = 'update'
        end

      elsif event[:name] == 'Ticket'
        ticket  = Ticket.lookup( id: event[:id] )

        # next if ticket is already deleted
        next if !ticket

        if !listObjects[ticket.id]
          listObjects[ticket.id] = {}
        end
        listObjects[ticket.id][:ticket_id] = ticket.id

        if !listObjects[ticket.id][:type] || listObjects[ticket.id][:type] == 'update'
          listObjects[ticket.id][:type] = event[:type]
        end

        # merge changes
        if event[:changes]
          if !listObjects[ticket.id][:changes]
            listObjects[ticket.id][:changes] = event[:changes]
          else
            event[:changes].each {|key, value|
              if !listObjects[ticket.id][:changes][key]
                listObjects[ticket.id][:changes][key] = value
              else
                listObjects[ticket.id][:changes][key][1] = value[1]
              end
            }
          end
        end
      else
        raise "unknown object for notification #{event[:name]}"
      end
    }
    listObjects
  end

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # logger.info 'CREATED!!!!'
    # logger.info record.inspect
    e = {
      name: record.class.name,
      type: 'create',
      data: record,
      id: record.id,
    }
    EventBuffer.add(e)
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # ignore updates on articles / we just want send notifications on ticket updates
    return if record.class.name == 'Ticket::Article'

    # ignore certain attributes
    real_changes = {}
    record.changes.each {|key, value|
      next if key == 'updated_at'
      next if key == 'first_response'
      next if key == 'close_time'
      next if key == 'last_contact_agent'
      next if key == 'last_contact_customer'
      next if key == 'last_contact'
      next if key == 'article_count'
      next if key == 'create_article_type_id'
      next if key == 'create_article_sender_id'
      real_changes[key] = value
    }

    # do not send anything if nothing has changed
    return if real_changes.empty?

    e = {
      name: record.class.name,
      type: 'update',
      data: record,
      changes: real_changes,
      id: record.id,
    }
    EventBuffer.add(e)
  end

  def after_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # logger.info 'after_update'
    # logger.info record.inspect
    # logger.info '-----'
    # logger.info @a.inspect
    # AuditTrail.new(record, "UPDATED")
  end
end
