# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ExceptionsPolicy < ApplicationPolicy
  # We want to avoid leaking of internal information but also want the user
  # to give the administrator a reference to find the cause of the error.
  # Therefore we generate a one time unique error ID that can be used to
  # search the logs and find the actual error message.
  def view_details?
    user&.permissions?('admin')
  end
end
