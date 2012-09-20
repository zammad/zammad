module ExtraRoutes
  def add(map)

    map.match '/api/activity_stream',           :to => 'activity#activity_stream'

  end
  module_function :add
end