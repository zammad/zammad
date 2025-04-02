# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth
  include ::Mixin::HasBackends

  def self.run(user, session, options: {})
    backends.each do |backend|
      result = backend.run(
        user:    user,
        session: session,
        options: options,
      )

      return result if result.present?
    end

    nil
  end
end
