module ExtraRoutes
  def add(map)

    map.match '/api/activity_stream',   :to => 'activity#activity_stream', :via => :get

  end
  module_function :add
end
