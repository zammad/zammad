# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      # Need to explicitly cast to boolean
      # because this setting was formerly stored as int
      # See fix for:
      # https://github.com/zammad/zammad/issues/5053
      ActiveModel::Type::Boolean.new.cast(Setting.get('password_need_special_character'))
    end
  end
end
