# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module SessionHelper::CollectionAdmin

  module_function

  def session(collections, assets, user)
    return [collections, assets] if !user.permissions?('admin.*')

    [Calendar, Webhook, AI::Agent].each do |klass|
      app_model = klass.to_app_model
      collections[ app_model ] = []
      klass.find_each do |elem|
        assets = elem.assets(assets)
      end
    end

    [collections, assets]
  end
end
