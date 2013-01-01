class EmailAddress < ApplicationModel
  has_many                :groups,   :after_add => :cache_update, :after_remove => :cache_update
  validates               :realname, :presence => true
  validates               :email,    :presence => true
end
