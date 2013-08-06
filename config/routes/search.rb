module ExtraRoutes
  def add(map, api_path)

    # search
    map.match api_path + '/search',        	:to => 'search#search', :via => [:get, :post]

  end
  module_function :add
end