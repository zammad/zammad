class RoomAttributeAssignment < ActiveRecord::Base
  self.primary_keys = :dorm_id, :room_id, :room_attribute_id
  belongs_to :room, :foreign_key => [:dorm_id, :room_id]
  belongs_to :room_attribute
end