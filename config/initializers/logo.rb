# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

Rails.application.reloader.to_prepare do

  next if !ActiveRecord::Base.connected?

  # sync logo to fs / only if settings already exists
  next if ActiveRecord::Base.connection.tables.exclude?('settings')
  next if Setting.column_names.exclude?('state_current')

  StaticAssets.sync
end
