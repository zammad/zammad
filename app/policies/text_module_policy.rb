# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TextModulePolicy < ApplicationPolicy

  def show?
    return true if user.permissions?('admin.text_module')
    return false if !user.permissions?('ticket.agent')

    if record.group_ids.any?
      return record.group_ids.intersect?(user.group_ids_access('read'))
    end

    true
  end

end
