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

  private

  def validate_access
    query = self.class.where(group: group, user: user)

    query = if access == 'full'
              query.where.not(access: 'full')
            else
              query.where(access: 'full')
            end

    errors.add(:access, 'User can have full or granular access to group') if query.exists?
  end

  validate :validate_access
end
