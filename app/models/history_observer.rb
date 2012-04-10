class HistoryObserver < ActiveRecord::Observer
  include UserInfo
  observe :ticket, :user, 'ticket::_article'

  def after_create(record)
    puts 'HISTORY OBSERVER CREATE !!!!' + record.class.name
    puts record.inspect
      
    history_type = History::Type.where( :name => 'created' ).first
    if !history_type || !history_type.id
      history_type = History::Type.create(
        :name   => 'created'
      )
    end
    history_object = History::Object.where( :name => record.class.name ).first
    if !history_object || !history_object.id
      history_object = History::Object.create(
        :name   => record.class.name
      )
    end
    
    History.create(
      :o_id                        => record.id,
      :history_type_id             => history_type.id,
      :history_object_id           => history_object.id,
      :created_by_id               => current_user_id || record.created_by_id || 1
    )
#      :name => record.class.name,
#      :type => 'create',
#      :data => record
  end

  def before_update(record)
    puts 'before_update'
    current = record.class.find(record.id)

    # do not send anything if nothing has changed
    if current.attributes == record.attributes
      return
    end
  
    puts 'HISTORY OBSERVER UPDATE!!!!' + record.class.name
    puts 'current'
    puts current.inspect
    puts 'record'
    puts record.inspect
    
    diff = differences_from?(current, record)
    puts 'DIFF'
    puts diff.inspect
    puts 'CURRENT O_ID'
    puts current.id
    puts 'CURRENT USER ID'
    puts current_user_id

    history_type = History::Type.where( :name => 'updated' ).first
    if !history_type || !history_type.id
      history_type = History::Type.create(
        :name   => 'updated'
      )
    end
    history_object = History::Object.where( :name => record.class.name ).first
    if !history_object || !history_object.id
      history_object = History::Object.create(
        :name   => record.class.name
      )
    end
    
    map = {
      :group_id => {
        :attribute        => 'Group',

        :lookup_object => Group,
        :lookup_name   => 'name',
      },
      :title => {
        :attribute        => 'Title',
      },
      :number => {
        :attribute        => 'Number',
      },
      :owner_id => {
        :attribute        => 'Owner',

        :lookup_object    => User,
        :lookup_name      => ['firstname', 'lastname'],
      },
      :ticket_state_id => {
        :attribute        => 'State',
        
        :lookup_object    => Ticket::State,
        :lookup_name      => 'name',
      },
      :ticket_priority_id => {
        :attribute        => 'Priority',

        :lookup_object    => Ticket::Priority,
        :lookup_name      => 'name',
      }
    }
    
    diff.each do |key, value_ids|
      puts "#{key} is #{value_ids}"
      
      # check if diff are ids, if yes do lookup
      value = []
      if map[key.to_sym] && map[key.to_sym][:lookup_object]
        value[0] = ''
        value[1] = ''
        if map[key.to_sym][:lookup_name].class == Array
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
        else
          value[0] = map[key.to_sym][:lookup_object].find(value_ids[0])[map[key.to_sym][:lookup_name]]
          value[1] = map[key.to_sym][:lookup_object].find(value_ids[1])[map[key.to_sym][:lookup_name]]
        end

      # if not, fill diff data to value, empty value_ids
      else
        value = value_ids
        value_ids = []
      end
      
      attribute_name = ''
      if map[key.to_sym] && map[key.to_sym][:attribute].to_s
        attribute_name = map[key.to_sym][:attribute].to_s
      else
        attribute_name = key
      end
puts 'LLLLLLLLLLLLLLLLLLLLLLLL' + attribute_name.to_s
      attribute = History::Attribute.where( :name => attribute_name.to_s ).first
      if !attribute || !attribute.object_id
        attribute = History::Attribute.create(
          :name   => attribute_name
        )
      end
#        puts '9999999'
#        puts current.object_id
#        puts current.id
      History.create(
        :o_id                        => current.id,
        :history_type_id             => history_type.id,
        :history_object_id           => history_object.id,
        :history_attribute_id        => attribute.id,
        :value_from                  => value[0],
        :value_to                    => value[1],
        :id_from                     => value_ids[0],
        :id_to                       => value_ids[1],
        :created_by_id               => current_user_id || 1 || self['created_by_id'] || 1
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