class Role < ApplicationModel
  has_and_belongs_to_many :users
  after_create            :cache_delete
  after_update            :cache_delete
  after_destroy           :cache_delete
end
