# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Transaction < ActiveRecord::Observer
  observe :ticket, 'ticket::_article'

  def self.commit(params = {})

    # add attribute if execution is via web
    params[:via_web] = false
    if ENV['RACK_ENV'] || Rails.configuration.webserver_is_active
      params[:via_web] = true
    end

    # execute object transactions
    Observer::Transaction.perform(params)
  end

  def self.perform(params)

    # return if we run import mode
    return if Setting.get('import_mode')

    # get buffer
    list = EventBuffer.list('transaction')

    # reset buffer
    EventBuffer.reset('transaction')

    # get uniq objects
    list_objects = get_uniq_changes(list)
    list_objects.each {|_id, item|

      # send background job
      Delayed::Job.enqueue(Transaction::BackgroundJob.new(item, params))
    }
  end

=begin

  result = get_uniq_changes(events)

  result = {
    1 => {
      object: 'Ticket',
      type: 'create',
      ticket_id: 123,
      article_id: 123,
    },
    9 => {
      object: 'Ticket',
      type: 'update',
      ticket_id: 123,
      changes: {
        attribute1: [before, now],
        attribute2: [before, now],
      }
    },
  }

  result = {
    9 => {
      object: 'Ticket',
      type: 'update',
      ticket_id: 123,
      article_id: 123,
      changes: {
        attribute1: [before, now],
        attribute2: [before, now],
      }
    },
  }

=end

  def self.get_uniq_changes(events)
    list_objects = {}
    events.each { |event|

      # get current state of objects
      if event[:name] == 'Ticket::Article'
        article = Ticket::Article.lookup(id: event[:id])

        # next if article is already deleted
        next if !article

        ticket = article.ticket
        if !list_objects[ticket.id]
          list_objects[ticket.id] = {}
        end
        list_objects[ticket.id][:object] = 'Ticket'
        list_objects[ticket.id][:article_id] = article.id
        list_objects[ticket.id][:ticket_id]  = ticket.id

        if !list_objects[ticket.id][:type]
          list_objects[ticket.id][:type] = 'update'
        end

      elsif event[:name] == 'Ticket'
        ticket = Ticket.lookup(id: event[:id])

        # next if ticket is already deleted
        next if !ticket

        if !list_objects[ticket.id]
          list_objects[ticket.id] = {}
        end
        list_objects[ticket.id][:object] = 'Ticket'
        list_objects[ticket.id][:ticket_id] = ticket.id

        if !list_objects[ticket.id][:type] || list_objects[ticket.id][:type] == 'update'
          list_objects[ticket.id][:type] = event[:type]
        end

        # merge changes
        if event[:changes]
          if !list_objects[ticket.id][:changes]
            list_objects[ticket.id][:changes] = event[:changes]
          else
            event[:changes].each {|key, value|
              if !list_objects[ticket.id][:changes][key]
                list_objects[ticket.id][:changes][key] = value
              else
                list_objects[ticket.id][:changes][key][1] = value[1]
              end
            }
          end
        end
      else
        raise "unknown object for integration #{event[:name]}"
      end
    }
    list_objects
  end

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    e = {
      name: record.class.name,
      type: 'create',
      data: record,
      id: record.id,
    }
    EventBuffer.add('transaction', e)
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # ignore updates on articles / we just want send integrations on ticket updates
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
    EventBuffer.add('transaction', e)
  end

end
