module ExtraRoutes
  def add(map)

    # base objects
    map.match '/api/settings',                       :to => 'settings#index',   :via => :get
    map.match '/api/settings/:id',                   :to => 'settings#show',    :via => :get
    map.match '/api/settings',                       :to => 'settings#create',  :via => :post
    map.match '/api/settings/:id',                   :to => 'settings#update',  :via => :put
    map.match '/api/settings/:id',                   :to => 'settings#destroy', :via => :delete

  end
  module_function :add
end