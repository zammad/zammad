module ExtraRoutes
  def add(map)

    map.match '/test',            :to => 'tests#index', :via => :get
    map.match '/test/wait/:sec',  :to => 'tests#wait',  :via => :get

  end
  module_function :add
end
