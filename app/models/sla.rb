class Sla < ApplicationModel
  store     :condition
  store     :data
  validates :name, :presence => true
end