# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Auth
  class Internal < Auth::Base

    def valid?(user, password)

      return false if user.blank?

      if PasswordHash.legacy?(user.password, password)
        update_password(user, password)
        return true
      end

      password_verified = PasswordHash.verified?(user.password, password)

      raise Exceptions::Forbidden, 'Please verify your account before you can login!' if !user.verified && user.source == 'signup' && password_verified

      password_verified
    end

    private

    def update_password(user, password)
      user.password = PasswordHash.crypt(password)
      user.save
    end
  end
end
