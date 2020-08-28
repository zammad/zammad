class PasswordPolicy
  class UpperAndLowerCaseCharacters < PasswordPolicy::Backend

    UPPER_LOWER_REGEXPS = [/\p{Upper}.*\p{Upper}/, /\p{Lower}.*\p{Lower}/].freeze

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
