# sync logo to fs / only if settings already exists
if ActiveRecord::Base.connection.tables.include?('settings')
  StaticAssets.sync
end