class Student < ActiveRecord::Base
  has_many :room_assignments, :dependent => :destroy
  has_many :rooms, :through => :room_assignments, :foreign_key => [:building_code, :room_number]
end