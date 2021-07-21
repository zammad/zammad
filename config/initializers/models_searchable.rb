# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# update settings for searchable models

Rails.application.reloader.to_prepare do
  begin
    next if !Setting.exists?(name: 'models_searchable')

    Setting.set('models_searchable', Models.searchable.map(&:to_s))
  rescue ActiveRecord::StatementInvalid
    nil
  end
end
