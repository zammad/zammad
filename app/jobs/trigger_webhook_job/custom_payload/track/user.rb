# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::User < TriggerWebhookJob::CustomPayload::Track
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
