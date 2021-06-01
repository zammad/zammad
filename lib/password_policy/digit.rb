# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PasswordPolicy
  class Digit < PasswordPolicy::Backend

    NEED_DIGIT_REGEXP = %r{\d}.freeze

    def valid?
      @password.match? NEED_DIGIT_REGEXP
    end

    def error
      ['Invalid password, it must contain at least 1 digit!']
    end

    def self.applicable?
      Setting.get('password_need_digit').to_i == 1
    end
  end
end
