module ExtraRoutes
  def add(map, api_path)

    map.match api_path + '/activity_stream',   :to => 'activity#activity_stream', :via => :get

  end
  module_function :add
end
