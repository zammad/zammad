# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AccessToken::List < Service::Base
  attr_reader :user

  def initialize(user)
    super()

    @user = user
  end

  def execute
    user
      .tokens
      .without_sensitive_columns
      .where(action: 'api', persistent: true)
      .reorder(updated_at: :desc, name: :asc)
  end
end
