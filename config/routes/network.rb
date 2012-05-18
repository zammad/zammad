module ExtraRoutes
  def add(map)

    # networks
    map.resources :networks,            :only => [:create, :show, :index, :update, :destroy]

  end
  module_function :add
end