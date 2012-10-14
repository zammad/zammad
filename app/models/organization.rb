class Organization < ApplicationModel
  has_and_belongs_to_many :users
  validates               :name, :presence => true
end
