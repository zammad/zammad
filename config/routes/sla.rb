module ExtraRoutes
  def add(map)

    # slas
    map.match '/api/slas',                       :to => 'slas#index',   :via => :get
    map.match '/api/slas/:id',                   :to => 'slas#show',    :via => :get
    map.match '/api/slas',                       :to => 'slas#create',  :via => :post
    map.match '/api/slas/:id',                   :to => 'slas#update',  :via => :put
    map.match '/api/slas/:id',                   :to => 'slas#destroy', :via => :delete

  end
  module_function :add
end