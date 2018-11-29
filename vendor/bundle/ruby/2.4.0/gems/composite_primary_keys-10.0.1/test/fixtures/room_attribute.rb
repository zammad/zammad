class RoomAttribute < ActiveRecord::Base
  has_many :rooms, :through => :room_attribute_assignments, :foreign_key => [:dorm_id, :room_id]
end