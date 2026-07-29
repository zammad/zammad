# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflowPolicy < ApplicationPolicy
  def show?
    user.permissions?('admin.core_workflow')
  end
end
