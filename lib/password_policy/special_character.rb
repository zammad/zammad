# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PasswordPolicy
  class SpecialCharacter < PasswordPolicy::Backend

    NEED_SPECIAL_CHARACTER_REGEXP = %r{\W}

    def valid?
      @password.match? NEED_SPECIAL_CHARACTER_REGEXP
    end

    def error
      [__('Invalid password, it must contain at least 1 special character!')]
    end

    def self.applicable?
      Setting.get('password_need_special_character').to_i == 1
    end
  end
end
