module ExtraRoutes
  def add(map)

    # templates
    map.match '/api/templates',                       :to => 'templates#index',   :via => :get
    map.match '/api/templates/:id',                   :to => 'templates#show',    :via => :get
    map.match '/api/templates',                       :to => 'templates#create',  :via => :post
    map.match '/api/templates/:id',                   :to => 'templates#update',  :via => :put
    map.match '/api/templates/:id',                   :to => 'templates#destroy', :via => :delete

  end
  module_function :add
end