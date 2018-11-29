class Suburb < ActiveRecord::Base
  self.primary_keys = :city_id, :suburb_id
  has_many :streets,  :foreign_key => [:city_id, :suburb_id]
  has_many :first_streets, -> {where("streets.name = 'First Street'")},
           :foreign_key => [:city_id, :suburb_id], :class_name => 'Street'
end