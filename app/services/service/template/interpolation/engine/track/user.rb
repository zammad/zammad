# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track::User < Service::Template::Interpolation::Engine::Track
  def self.klass
    'User'
  end

  def self.functions
    super - %w[
      last_login
      login_failed
      password
      preferences
      group_ids
      authorization_ids
    ].freeze + %w[
      fullname
    ].freeze
  end
end
