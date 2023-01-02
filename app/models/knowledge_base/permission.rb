# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Permission < ApplicationModel
  belongs_to :permissionable, polymorphic: true, touch: true
  belongs_to :role

  validates :role, uniqueness: { scope: %i[permissionable_id permissionable_type] }

  validate :ensure_access_matches_role

  # cache key for calculated permissions
  # @param permissionable [KnowledgeBase::Category, KnowledgeBase]
  # @return [String]
  def self.cache_key(permissionable)
    "#{self}/#{latest_change}/#{permissionable.class}/#{permissionable.class.latest_change}/permission/#{permissionable.id}"
  end

  private

  def ensure_access_matches_role
    return if role.blank?
    return if allowed_access.include? access

    errors.add :base, __('This permission level is not available based on the current roles permissions.')
  end

  def allowed_access
    if role.with_permission? 'knowledge_base.editor'
      %w[editor reader none]
    elsif role.with_permission? 'knowledge_base.reader'
      %w[reader none]
    else
      []
    end
  end
end
