# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::Backend
  attr_accessor :current_user

  def initialize(current_user:, object_ids: {})
    @current_user = current_user
    @object_ids   = object_ids
  end

  private

  def ticket_ids
    @object_ids[:ticket_ids]
  end

  def user_ids
    @object_ids[:user_ids]
  end

  def organization_ids
    @object_ids[:organization_ids]
  end
end
