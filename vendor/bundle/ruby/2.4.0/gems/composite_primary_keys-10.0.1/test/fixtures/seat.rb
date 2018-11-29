class Seat < ActiveRecord::Base
  self.primary_keys = [:flight_number, :seat]

  validates_uniqueness_of :customer
end
