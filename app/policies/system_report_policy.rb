# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReportPolicy < ApplicationPolicy
  def show?
    user.permissions?('admin.system_report')
  end
end
