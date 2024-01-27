# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChannelPolicy < ApplicationPolicy
  def create?
    access?
  end

  def destroy?
    access?
  end

  def update?
    access?
  end

  def show?
    access?
  end

  private

  def permission_name
    area_provider = record.area.split('::').first.downcase

    "admin.channel_#{area_provider}"
  end

  def access?
    user.permissions?(permission_name)
  end
end
