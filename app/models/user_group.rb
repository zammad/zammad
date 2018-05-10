# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UserGroup < ApplicationModel
  self.table_name   = 'groups_users'
  self.primary_keys = :user_id, :group_id, :access
  belongs_to          :user
  belongs_to          :group
  validates           :access, presence: true

  def self.ref_key
    :user_id
  end

  def cache_update
    group.cache_update(nil)
    user.cache_update(nil)
    super
  end

  def cache_delete
    group.cache_update(nil)
    user.cache_update(nil)
    super
  end
end
