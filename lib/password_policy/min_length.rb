# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PasswordPolicy
  class MinLength < PasswordPolicy::Backend

    def valid?
      Setting.get('password_min_size').to_i <= @password.length
    end

    def error
      [__('Invalid password, it must be at least %s characters long!'), Setting.get('password_min_size')]
    end

    def self.applicable?
      true
    end
  end
end
