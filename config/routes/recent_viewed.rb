module ExtraRoutes
  def add(map, api_path)

    map.match api_path + '/recent_viewed',     :to => 'recent_viewed#recent_viewed', :via => :get

  end
  module_function :add
end
