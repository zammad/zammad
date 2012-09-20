module ExtraRoutes
  def add(map)

    # getting_started
    map.match '/api/getting_started',             :to => 'getting_started#index'

  end
  module_function :add
end