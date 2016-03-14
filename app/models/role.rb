# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Role < ApplicationModel

  has_and_belongs_to_many   :users, after_add: :cache_update, after_remove: :cache_update
  validates                 :name,  presence: true
  activity_stream_support   role: Z_ROLENAME_ADMIN
  notify_clients_support
  latest_change_support
end
