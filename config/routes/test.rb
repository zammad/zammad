module ExtraRoutes
  def add(map, api_path)

    map.match '/tests-core',      :to => 'tests#core',  :via => :get
    map.match '/tests-form',      :to => 'tests#form',  :via => :get
    map.match '/tests/wait/:sec', :to => 'tests#wait',  :via => :get

  end
  module_function :add
end
