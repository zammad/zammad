# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class Backend
    class Internal < Auth::Backend::Base

      private

      # Validation against the internal database.
      #
      # @returns [Boolean] true if the validation works, otherwise false.
      def authenticated?
        return true if hash_matches?

        auth.increase_login_failed_attempts = true

        false
      end

      # Overwrites the default behaviour to only perform this authentication if an internal password exists.
      #
      # @returns [Boolean] true if a internal password for the user is present.
      def perform?
        return false if !user.verified && user.source == 'signup'

        user.password.present?
      end

      def hash_matches?
        # makes sure that very long strings supplied as password
        # rejected early and not even tried to match to password
        if !PasswordPolicy::MaxLength.valid? password
          return false
        end

        # Because of legacy reason a special check exists and afterwards the
        # password will be saved in the current format.
        if PasswordHash.legacy?(user.password, password)
          user.update!(password: password)
          return true
        end

        PasswordHash.verified?(user.password, password)
      end
    end
  end
end
