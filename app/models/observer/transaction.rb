# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Transaction < ActiveRecord::Observer
  observe :ticket, 'ticket::_article', :user, :organization

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
    list_objects.each {|_object, objects|
      objects.each {|_id, item|
        Delayed::Job.enqueue(Transaction::BackgroundJob.new(item, params))
      }
    }
  end

=begin

  result = get_uniq_changes(events)

  result = {
    'Ticket' =>
      1 => {
        object: 'Ticket',
        type: 'create',
        object_id: 123,
        article_id: 123,
      },
      9 => {
        object: 'Ticket',
        type: 'update',
        object_id: 123,
        changes: {
          attribute1: [before, now],
          attribute2: [before, now],
        },
      },
    },
  }

  result = {
    'Ticket' =>
      9 => {
        object: 'Ticket',
        type: 'update',
        object_id: 123,
        article_id: 123,
        changes: {
          attribute1: [before, now],
          attribute2: [before, now],
        },
      },
    },
  }

=end

  def self.get_uniq_changes(events)
    list_objects = {}
    events.each { |event|

      # simulate article create as ticket update
      article = nil
      if event[:object] == 'Ticket::Article'
        article = Ticket::Article.lookup(id: event[:id])
        next if !article
        next if event[:type] == 'update'

        # set new event infos
        ticket = Ticket.lookup(id: article.ticket_id)
        event[:object] = 'Ticket'
        event[:id] = ticket.id
        event[:type] = 'update'
        event[:changes] = nil
      end

      # get current state of objects
      object = Kernel.const_get(event[:object]).lookup(id: event[:id])

      # next if object is already deleted
      next if !object

      if !list_objects[event[:object]]
        list_objects[event[:object]] = {}
      end
      if !list_objects[event[:object]][object.id]
        list_objects[event[:object]][object.id] = {}
      end
      store = list_objects[event[:object]][object.id]
      store[:object] = event[:object]
      store[:object_id] = object.id

      if !store[:type] || store[:type] == 'update'
        store[:type] = event[:type]
      end

      # merge changes
      if event[:changes]
        if !store[:changes]
          store[:changes] = event[:changes]
        else
          event[:changes].each {|key, value|
            if !store[:changes][key]
              store[:changes][key] = value
            else
              store[:changes][key][1] = value[1]
            end
          }
        end
      end

      # remember article id if exists
      if article
        store[:article_id] = article.id
      end
    }
    list_objects
  end

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    e = {
      object: record.class.name,
      type: 'create',
      data: record,
      id: record.id,
    }
    EventBuffer.add('transaction', e)
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

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
      object: record.class.name,
      type: 'update',
      data: record,
      changes: real_changes,
      id: record.id,
    }
    EventBuffer.add('transaction', e)
  end

end
