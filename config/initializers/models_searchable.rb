# update settings for searchable models
if ActiveRecord::Base.connection.tables.include?('settings')
  if Setting.columns_hash.key?('state_current') # TODO: remove me later
    models_current = Models.searchable.map(&:to_s)
    models_config = Setting.get('models_searchable')
    setting = Setting.find_by(name: 'models_searchable')
    if setting && models_current != models_config
      Setting.set('models_searchable', models_current)
    end
  end
end
