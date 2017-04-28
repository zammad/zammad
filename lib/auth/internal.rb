# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Auth
  class Internal < Auth::Base

    def valid?(user, password)

      return false if user.blank?

      if PasswordHash.legacy?(user.password, password)
        update_password(user, password)
        return true
      end

      PasswordHash.verified?(user.password, password)
    end

    private

    def update_password(user, password)
      user.password = PasswordHash.crypt(password)
      user.save
    end
  end
end
