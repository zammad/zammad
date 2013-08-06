module ExtraRoutes
  def add(map, api_path)

    # getting_started
    map.match api_path + '/getting_started',       :to => 'getting_started#index', :via => :get

  end
  module_function :add
end
