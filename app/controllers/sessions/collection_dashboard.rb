# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection

  module_function

  def session( collections, assets, user )
    return [collections, assets] if !user

    item = StatsStore.find_by(
      stats_storable: user,
      key:            'dashboard',
    )
    return [collections, assets] if !item

    collections['StatsStore'] = [item]

    [collections, assets]
  end
end
