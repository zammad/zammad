# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Permission < ApplicationModel
  belongs_to :permissionable, polymorphic: true, touch: true
  belongs_to :role

  validates :access, inclusion: { in: %w[editor reader none] }
  validates :role, uniqueness: { scope: %i[permissionable_id permissionable_type] }

  # cache key for calculated permissions
  # @param permissionable [KnowledgeBase::Category, KnowledgeBase]
  # @return [String]
  def self.cache_key(permissionable)
    "#{permissionable.class}::aws::#{permissionable.id}::permission::#{permissionable.updated_at}"
  end
end
