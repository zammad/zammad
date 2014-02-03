# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class EmailAddress < ApplicationModel
  has_many                :groups,   :after_add => :cache_update, :after_remove => :cache_update
  validates               :realname, :presence => true
  validates               :email,    :presence => true
end
