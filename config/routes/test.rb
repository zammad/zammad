module ExtraRoutes
  def add(map)

    map.match '/test',            :to => 'tests#index'
    map.match '/test/wait/:sec',  :to => 'tests#wait'

  end
  module_function :add
end