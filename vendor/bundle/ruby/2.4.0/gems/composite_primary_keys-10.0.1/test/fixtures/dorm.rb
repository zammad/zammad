class Dorm < ActiveRecord::Base
  has_many :rooms, -> {includes(:room_attributes)}, :primary_key => [:id]
end