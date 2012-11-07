class HistoryObserver < ActiveRecord::Observer
  include UserInfo
  observe :ticket, :user, 'ticket::_article'

  def after_create(record)
    puts 'HISTORY OBSERVER, object created !!!!' + record.class.name
#    puts record.inspect
    related_o_id = nil
    related_history_object_id = nil
    if record.class.name == 'Ticket::Article'
      related_o_id = record.ticket_id
      related_history_object = 'Ticket'
    end
    History.history_create(
      :o_id                   => record.id,
      :history_type           => 'created',
      :history_object         => record.class.name,
      :related_o_id           => related_o_id,
      :related_history_object => related_history_object,
      :created_by_id          => current_user_id || record.created_by_id || 1
    )
  end

  def before_update(record)
    puts 'before_update'
    current = record.class.find(record.id)

    # do not send anything if nothing has changed
    if current.attributes == record.attributes
      return
    end
  
    puts 'HISTORY OBSERVER object will be updated!!!!' + record.class.name
#    puts 'current'
#    puts current.inspect
#    puts 'record'
#    puts record.inspect
    
    diff = differences_from?(current, record)
    puts 'DIFF'
    puts diff.inspect
    puts 'CURRENT O_ID ' + current.id.to_s
    puts 'CURRENT USER ID ' + current_user_id.to_s

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
    
    diff.each do |key, value_ids|
      
      # do not log created_at and updated_at attributes
      next if key.to_s == 'created_at'
      next if key.to_s == 'updated_at'

      puts "#{key} is #{value_ids.inspect}"

      # check if diff are ids, if yes do lookup
      if value_ids[0].to_s == value_ids[1].to_s
        puts 'NEXT!!'
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
#puts 'LLLLLLLLLLLLLLLLLLLLLLLL' + attribute_name.to_s
#        puts '9999999'
#        puts current.id
      History.history_create(
        :o_id               => current.id,
        :history_type       => 'updated',
        :history_object     => record.class.name,
        :history_attribute  => attribute_name,
        :value_from         => value[0],
        :value_to           => value[1],
        :id_from            => value_ids[0],
        :id_to              => value_ids[1],
        :created_by_id      => current_user_id || 1 || self['created_by_id'] || 1
      )

    end
    
#      :name => record.class.name,
#      :type => 'update',
#      :data => record
  end

  def differences_from?(one, other)
#    puts '1111'+one.inspect
#    puts '2222'+other.inspect
    h = {}
    one.attributes.each_pair do |key, value|
      if one[key] != other[key]
        h[key.to_sym] = [ one[key], other[key] ]
      end  
    end    
    h
  end  
end