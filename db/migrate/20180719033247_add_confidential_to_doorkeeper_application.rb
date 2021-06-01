# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration[5.1]
  def change
    return if ActiveRecord::Base.connection.column_exists?(:oauth_applications, :confidential)

    add_column(
      :oauth_applications,
      :confidential,
      :boolean,
      null:    false,
      default: true # maintaining backwards compatibility: require secrets
    )
  end
end
