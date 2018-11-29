class Room < ActiveRecord::Base
  self.primary_keys = :dorm_id, :room_id
  belongs_to :dorm
  has_many :room_assignments, :foreign_key =>  [:dorm_id, :room_id]
  has_many :room_attribute_assignments, :foreign_key =>  [:dorm_id, :room_id]
  has_many :room_attributes, :through => :room_attribute_assignments
  
  def find_custom_room_attributes
    room_attributes.where("room_attributes.name != ?", "type")
  end
end
