class History < ActiveRecord::Base
  self.table_name = 'histories'
  belongs_to :history_type,             :class_name => 'History::Type'
  belongs_to :history_object,           :class_name => 'History::Object'
  belongs_to :history_attribute,        :class_name => 'History::Attribute'
#  before_validation :check_type, :check_object
#  attr_writer :history_type, :history_object

#  def history_type(a)
#  end
  
  def self.history_list(requested_object, requested_object_id)
    history = History.where( :history_object_id => History::Object.where( :name => requested_object ) ).
      where( :o_id => requested_object_id ).
      where( :history_type_id => History::Type.where( :name => ['created', 'updated']) ).
      order('created_at ASC, id ASC')
    return history
  end
  
  def self.activity_stream(user, limit = 10)
#    g = Group.where( :active => true ).joins(:users).where( 'users.id' => user.id )
#    stream = History.select("distinct(histories.o_id), created_by_id, history_attribute_id, history_type_id, history_object_id, value_from, value_to").
#      where( :history_type_id   => History::Type.where( :name => ['created', 'updated']) ).
    stream = History.select("distinct(histories.o_id), created_by_id, history_type_id, history_object_id").
      where( :history_object_id => History::Object.where( :name => 'Ticket').first.id ).
      where( :history_type_id   => History::Type.where( :name => ['updated']) ).
      order('created_at DESC, id DESC').
      limit(limit)
    datas = []
    stream.each do |item|
      data = item.attributes
      data['history_object'] = item.history_object
      data['history_type']   = item.history_type
      datas.push data
#      item['history_attribute'] = item.history_attribute
    end
    return datas
  end

  def self.recent_viewed(user)
#    g = Group.where( :active => true ).joins(:users).where( 'users.id' => user.id )
    stream = History.select("distinct(histories.o_id), created_by_id, history_attribute_id, history_type_id, history_object_id, value_from, value_to").
      where( :history_object_id => History::Object.where( :name => 'Ticket').first.id ).
      where( :history_type_id => History::Type.where( :name => ['viewed']) ).
      order('created_at DESC, id DESC').
      limit(10)
    datas = []
    stream.each do |item|
      data = item.attributes
      data['history_object'] = item.history_object
      data['history_type']   = item.history_type
      datas.push data
#      item['history_attribute'] = item.history_attribute
    end
    return datas
  end
  
  private
    def check_type
      puts '--------------'
      puts self.inspect
      history_type = History::Type.where( :name => self.history_type ).first
      if !history_type || !history_type.id
        history_type = History::Type.create(
          :name   => self.history_type,
          :active => true
        )
      end
      self.history_type_id = history_type.id
    end
    def check_object
      history_object = History::Object.where( :name => self.history_object ).first
      if !history_object || !history_object.id
        history_object = History::Object.create(
          :name   => self.history_object,
          :active => true
        )
      end
      self.history_object_id = history_object.id
    end

  class Object < ActiveRecord::Base
  end

  class Type < ActiveRecord::Base
  end

  class Attribute < ActiveRecord::Base
  end

end
