# update settings for searchable models
if ActiveRecord::Base.connection.tables.include?('settings')
  models_current = Models.searchable.map(&:to_s)
  models_config = Setting.get('models_searchable')
  if models_current != models_config
    Setting.set('models_searchable', models_current)
  end
end
