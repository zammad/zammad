# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Token::Permissions
  extend ActiveSupport::Concern

  def permissions
    Permission.where(
      name:   Array(preferences[:permission]),
      active: true,
    )
  end

  def permissions?(query)
    effective_user.permissions?(query) && Auth::Permissions.authorized?(self, query)
  end

  def permissions!(query)
    return true if permissions?(query)

    raise Exceptions::Forbidden, __('Token authorization failed.')
  end
end
