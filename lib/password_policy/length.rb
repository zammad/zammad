class PasswordPolicy
  class Length < PasswordPolicy::Backend

    def valid?
      Setting.get('password_min_size').to_i <= @password.length
    end

    def error
      ['Invalid password, it must be at least %s characters long!', Setting.get('password_min_size')]
    end

    def self.applicable?
      true
    end
  end
end
