# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module SessionHelper::CollectionObjectManagerAttribute

  module_function

  def session(collections, assets, user)
    return [collections, assets] if !user.permissions?('admin.*')

    collections[ ObjectManager::Attribute.to_app_model ] = ObjectManager::Attribute.list_full

    [collections, assets]
  end
end
