# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PasswordPolicy
  class MaxLength < PasswordPolicy::Backend
    MAX_LENGTH = 1_000

    def valid?
      self.class.valid? @password
    end

    def error
      self.class.error
    end

    def self.applicable?
      true
    end

    def self.valid?(input)
      input.length <= MAX_LENGTH
    end

    def self.error
      [__('Invalid password, it must be shorter than %s characters!'), MAX_LENGTH]
    end
  end
end
