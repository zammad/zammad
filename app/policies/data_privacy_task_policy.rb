# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTaskPolicy < ApplicationPolicy
  def show?
    user.permissions?('admin.data_privacy')
  end
end
