# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AccessToken::List < Service::Base
  requires_current_user!

  def execute
    current_user
      .tokens
      .without_sensitive_columns
      .where(action: 'api', persistent: true)
      .reorder(updated_at: :desc, name: :asc)
  end
end
