class Overview < ApplicationModel
  store     :condition
  store     :order
  store     :view
  validates :name, :presence => true
  validates :prio, :presence => true
  validates :link, :presence => true
end