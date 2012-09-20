module ExtraRoutes
  def add(map)

    map.match '/api/recent_viewed',             :to => 'recent_viewed#recent_viewed'

  end
  module_function :add
end