# update settings for searchable models

begin
  return if !Setting.exists?(name: 'models_searchable')

  Setting.set('models_searchable', Models.searchable.map(&:to_s))
rescue ActiveRecord::StatementInvalid
  nil
end
