# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Auth::Internal

  # rubocop:disable Style/ModuleFunction
  extend self

  def check(username, password, _config, user)

    # return if no user exists
    return false if !username
    return false if !user

    if PasswordHash.legacy?(user.password, password)
      update_password(user, password)
      return user
    end

    return false if !PasswordHash.verified?(user.password, password)

    user
  end

  private

  def update_password(user, password)
    user.password = PasswordHash.crypt(password)
    user.save
  end
end
