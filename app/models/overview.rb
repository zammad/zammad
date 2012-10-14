class Overview < ApplicationModel
  store     :condition
  store     :order
  store     :meta
  store     :view
  validates :name, :presence => true
end