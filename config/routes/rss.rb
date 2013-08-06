module ExtraRoutes
  def add(map, api_path)

    # rss
    map.match api_path + '/rss_fetch',   :to => 'rss#fetch', :via => :get

  end
  module_function :add
end
