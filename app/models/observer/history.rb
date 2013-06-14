# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'history'

class Observer::History < ActiveRecord::Observer
  observe :ticket, :user, 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    puts "HISTORY OBSERVER, object created #{ record.class.name }.find(#{ record.id })"
    #    puts record.inspect

    # if Ticket::Article has changed, remember ticket to be able
    # to show article changes in ticket history
    related_o_id              = nil
    related_history_object_id = nil
    if record.class.name == 'Ticket::Article'
      related_o_id           = record.ticket_id
      related_history_object = 'Ticket'
    end
    History.add(
      :o_id                   => record.id,
      :history_type           => 'created',
      :history_object         => record.class.name,
      :related_o_id           => related_o_id,
      :related_history_object => related_history_object,
      :created_by_id          => record.created_by_id || UserInfo.current_user_id || 1
    )
  end

  def before_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    #    puts 'before_update'
    current = record.class.find(record.id)

    # do not send anything if nothing has changed
    return if current.attributes == record.attributes

    puts "HISTORY OBSERVER, object will be updated #{ record.class.name.to_s}.find(#{ current.id.to_s })"
    #    puts 'current'
    #    puts current.inspect
    #    puts 'record'
    #    puts record.inspect

    diff = differences_from?(current, record)
    #puts ' DIFF'
    #puts ' ' + diff.inspect
    #puts ' CURRENT USER ID ' + UserInfo.current_user_id.to_s

    map = {
      :group_id => {
        :lookup_object => Group,
        :lookup_name   => 'name',
      },
      :owner_id => {
        :lookup_object  => User,
        :lookup_method  => 'fullname',
      },
      :ticket_state_id => {
        :lookup_object  => Ticket::State,
        :lookup_name    => 'name',
      },
      :ticket_priority_id => {
        :lookup_object  => Ticket::Priority,
        :lookup_name    => 'name',
      }
    }

    # TODO: Swop it to config file later
    ignore_attributes = {
      :created_at               => true,
      :updated_at               => true,
      :created_by_id            => true,
      :updated_by_id            => true,
      :article_count            => true,
      :create_article_type_id   => true,
      :create_article_sender_id => true,
    }

    diff.each do |key, value_ids|

      # do not log created_at and updated_at attributes
      next if ignore_attributes[key.to_sym] == true

      #puts " CHANGED: #{key} is #{value_ids.inspect}"

      # check if diff are ids, if yes do lookup
      if value_ids[0].to_s == value_ids[1].to_s
        #puts 'NEXT!!'
        next
      end

      # check if diff are ids, if yes do lookup
      value = []
      if map[key.to_sym] && map[key.to_sym][:lookup_object]
        value[0] = ''
        value[1] = ''

        # name base
        if map[key.to_sym][:lookup_name]
          if map[key.to_sym][:lookup_name].class != Array
            map[key.to_sym][:lookup_name] = [ map[key.to_sym][:lookup_name] ]
          end
          map[key.to_sym][:lookup_name].each do |item|
            if value[0] != ''
              value[0] = value[0] + ' '
            end
            value[0] = value[0] + map[key.to_sym][:lookup_object].find(value_ids[0])[item.to_sym].to_s
            if value[1] != ''
              value[1] = value[1] + ' '
            end
            value[1] = value[1] + map[key.to_sym][:lookup_object].find(value_ids[1])[item.to_sym].to_s
          end
        end

        # method base
        if map[key.to_sym][:lookup_method]
          value[0] = map[key.to_sym][:lookup_object].find( value_ids[0] ).send( map[key.to_sym][:lookup_method] )
          value[1] = map[key.to_sym][:lookup_object].find( value_ids[1] ).send( map[key.to_sym][:lookup_method] )
        end

        # if not, fill diff data to value, empty value_ids
      else
        value = value_ids
        value_ids = []
      end

      # get attribute name
      attribute_name = key.to_s
      if attribute_name.scan(/^(.*)_id$/).first
        attribute_name = attribute_name.scan(/^(.*)_id$/).first.first
      end

      # if Ticket::Article has changed, remember ticket to be able
      # to show article changes in ticket history
      related_o_id              = nil
      related_history_object_id = nil
      if record.class.name == 'Ticket::Article'
        related_o_id              = record.ticket_id
        related_history_object_id = 'Ticket'
      end
      History.add(
        :o_id                   => current.id,
        :history_type           => 'updated',
        :history_object         => record.class.name,
        :history_attribute      => attribute_name,
        :related_o_id           => related_o_id,
        :related_history_object => related_history_object_id,
        :value_from             => value[0],
        :value_to               => value[1],
        :id_from                => value_ids[0],
        :id_to                  => value_ids[1],
        :created_by_id          => record['updated_by_id'] || UserInfo.current_user_id || 1
      )

    end
  end

  def differences_from?(one, other)
    h = {}
    one.attributes.each_pair do |key, value|
      if one[key] != other[key]
        h[key.to_sym] = [ one[key], other[key] ]
      end
    end
    h
  end
end
