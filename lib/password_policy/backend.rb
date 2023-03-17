# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PasswordPolicy
  class Backend
    # @param password [String] to evaluate
    def initialize(password)
      @password = password
    end

    def valid?
      false
    end

    def error
      [__('Unknown error')]
    end

    def self.applicable?
      false
    end
  end
end
