# sync logo to fs / only if settings already exists
if ActiveRecord::Base.connection.tables.include?('settings')
  if Setting.column_names.include?('state_current')
    StaticAssets.sync
  end
end
