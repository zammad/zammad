class EmailAddress < ApplicationModel
  has_many                :groups,         :after_add => :cache_update, :after_remove => :cache_update
  after_create            :cache_delete
  after_update            :cache_delete
  after_destroy           :cache_delete
  validates               :realname, :presence => true
  validates               :email,    :presence => true
end
