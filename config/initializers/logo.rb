# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

return if !ActiveRecord::Base.connected?

# sync logo to fs / only if settings already exists
return if ActiveRecord::Base.connection.tables.exclude?('settings')
return if Setting.column_names.exclude?('state_current')

StaticAssets.sync
