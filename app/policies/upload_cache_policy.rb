# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UploadCachePolicy < ApplicationPolicy
  %i[
    add?
    any?
    attachments?
    destroy?
    remove_item?
    show?
  ].each do |action|
    define_method(action) { permission? }
  end

  private

  def permission?
    attachments = record.attachments
    return true if attachments.blank?

    attachments.first.created_by_id == user.id
  end
end
