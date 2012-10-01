class Group < ApplicationModel
  has_and_belongs_to_many :users,         :after_add => :cache_update, :after_remove => :cache_update
  belongs_to              :email_address
  belongs_to              :signature
  after_create            :cache_delete
  after_update            :cache_delete
  after_destroy           :cache_delete
end
