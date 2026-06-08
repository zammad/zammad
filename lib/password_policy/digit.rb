# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PasswordPolicy
  class Digit < PasswordPolicy::Backend

    NEED_DIGIT_REGEXP = %r{\d}

    def valid?
      @password.match? NEED_DIGIT_REGEXP
    end

    def error
      [__('Invalid password, it must contain at least 1 digit!')]
    end

    def self.applicable?
      # Need to explicitly cast to boolean
      # because this setting was formerly stored as int
      # See fix for:
      # https://github.com/zammad/zammad/issues/5053
      ActiveModel::Type::Boolean.new.cast(Setting.get('password_need_digit'))
    end
  end
end
