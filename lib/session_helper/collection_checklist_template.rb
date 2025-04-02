# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SessionHelper::CollectionChecklistTemplate

  module_function

  def session(collections, assets, _user)
    collections[ ChecklistTemplate.to_app_model ] = []
    ChecklistTemplate.all.each do |item|
      assets = item.assets(assets)
    end
    [collections, assets]
  end
end
