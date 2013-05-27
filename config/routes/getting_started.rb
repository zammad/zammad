module ExtraRoutes
  def add(map)

    # getting_started
    map.match '/api/getting_started',       :to => 'getting_started#index', :via => :get

  end
  module_function :add
end
