module ExtraRoutes
  def add(map)

    # roles
    map.match '/api/roles',                       :to => 'roles#index',   :via => :get
    map.match '/api/roles/:id',                   :to => 'roles#show',    :via => :get
    map.match '/api/roles',                       :to => 'roles#create',  :via => :post
    map.match '/api/roles/:id',                   :to => 'roles#update',  :via => :put

  end
  module_function :add
end