module ExtraRoutes
  def add(map)

    # search
    map.match '/api/search',                  :to => 'search#search', :via => [:get, :post]

  end
  module_function :add
end