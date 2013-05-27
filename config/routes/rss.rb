module ExtraRoutes
  def add(map)

    # rss
    map.match '/api/rss_fetch',   :to => 'rss#fetch', :via => :get

  end
  module_function :add
end
