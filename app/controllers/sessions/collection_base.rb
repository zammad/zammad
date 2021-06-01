# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection

  module_function

  def session( collections, assets, user )

    # all base stuff
    collections[ Locale.to_app_model ] = Locale.where(active: true)

    collections[ Taskbar.to_app_model ] = Taskbar.where(user_id: user.id)
    collections[ Taskbar.to_app_model ].each do |item|
      assets = item.assets(assets)
    end

    collections[ OnlineNotification.to_app_model ] = []
    OnlineNotification.list(user, 200).each do |item|
      assets = item.assets(assets)
    end

    collections[ RecentView.to_app_model ] = []
    RecentView.list(user, 10).each do |item|
      assets = item.assets(assets)
    end

    collections[ Permission.to_app_model ] = []
    Permission.all.each do |item|
      assets = item.assets(assets)
    end

    collections[ Role.to_app_model ] = []
    Role.all.each do |item|
      assets = item.assets(assets)
    end

    collections[ Group.to_app_model ] = []
    Group.all.each do |item|
      assets = item.assets(assets)
    end

    collections[ Organization.to_app_model ] = []
    if user.organization_id
      Organization.where(id: user.organization_id).each do |item|
        assets = item.assets(assets)
      end
    end

    [collections, assets]
  end
end
