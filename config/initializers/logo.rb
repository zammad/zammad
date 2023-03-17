# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Rails.application.reloader.to_prepare do

  begin
    # sync logo to fs / only if settings already exists
    next if ActiveRecord::Base.connection.tables.exclude?('settings')

    next if Setting.column_names.exclude?('state_current')

    StaticAssets.sync
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.debug("Database doesn't exist. Skipping StaticAssets.sync")
  end
end
