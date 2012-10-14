class PostmasterFilter < ApplicationModel
  store     :perform
  store     :match
  validates :name, :presence => true
end
