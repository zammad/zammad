# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PasswordPolicy
  class UpperAndLowerCaseCharacters < PasswordPolicy::Backend

    UPPER_LOWER_REGEXPS = [%r{\p{Upper}.*\p{Upper}}, %r{\p{Lower}.*\p{Lower}}].freeze

    def valid?
      UPPER_LOWER_REGEXPS.all? { |regexp| @password.match?(regexp) }
    end

    def error
      ['Invalid password, it must contain at least 2 lowercase and 2 uppercase characters!']
    end

    def self.applicable?
      Setting.get('password_min_2_lower_2_upper_characters').to_i == 1
    end
  end
end
