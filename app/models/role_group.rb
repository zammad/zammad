# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class RoleGroup < ApplicationModel
  self.table_name   = 'roles_groups'
  self.primary_keys = :role_id, :group_id, :access
  belongs_to          :role
  belongs_to          :group
  validates           :access, presence: true

  def self.ref_key
    :role_id
  end
end
