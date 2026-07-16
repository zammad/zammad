# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UploadCachePolicy < ApplicationPolicy
  %i[
    add?
    any?
    destroy?
    remove_item?
    show?
  ].each do |action|
    define_method(action) { permission? }
  end

  private

  def permission?
    !record.attachments(created_by_id: nil).exists? || record.attachments(created_by_id: user.id).exists?
  end
end
