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
        article = Ticket::Article.lookup( :id => event[:id] )

        # next if article is already deleted
        next if !article

        ticket = article.ticket
        if !listObjects[ticket.id]
          listObjects[ticket.id] = {}
        end
        listObjects[ticket.id][:article_id] = article.id

      elsif event[:name] == 'Ticket'
        ticket  = Ticket.lookup( :id => event[:id] )

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
    #current = record.class.find(record.id)

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

    return if real_changes.empty?

    human_changes = {}
    real_changes.each {|key, value|

      # get attribute name
      attribute_name = key.to_s
      if attribute_name[-3,3] == '_id'
        attribute_name = attribute_name[ 0, attribute_name.length-3 ]
      end
      if key == attribute_name
        human_changes[key] = value
      end

      value_id = []
      value_str = [ value[0], value[1] ]
      if key.to_s[-3,3] == '_id'
        value_id[0] = value[0]
        value_id[1] = value[1]

        if record.respond_to?( attribute_name ) && record.send(attribute_name)
          relation_class = record.send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup( :id => value_id[0] )
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup( :id => value_id[1] )
            if relation_model
              if relation_model['name']
                value_str[1] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[1] = relation_model.send('fullname')
              end
            end
          end
        end
      end
      human_changes[attribute_name] = [value_str[0].to_s, value_str[1].to_s]
    }

    # do not send anything if nothing has changed
    return if human_changes.empty?

    #    puts 'UPDATE!!!!!!!!'
    #    puts "changes #{record.changes.inspect}"
    #    puts 'current'
    #    puts current.inspect
    #    puts 'record'
    #    puts record.inspect

    e = {
      :name    => record.class.name,
      :type    => 'update',
      :data    => record,
      :changes => human_changes,
      :id      => record.id,
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