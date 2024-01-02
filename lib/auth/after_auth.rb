# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth
  include ::Mixin::HasBackends

  def self.run(user, session)
    backends.each do |backend|
      result = backend.run(
        user:    user,
        session: session,
      )

      return result if result.present?
    end

    nil
  end
end
