module ExtraRoutes
  def add(map)

    # organizations
    map.match '/api/organizations',                       :to => 'organizations#index',  :via => :get
    map.match '/api/organizations/:id',                   :to => 'organizations#show',   :via => :get
    map.match '/api/organizations',                       :to => 'organizations#create', :via => :post
    map.match '/api/organizations/:id',                   :to => 'organizations#update', :via => :put
    
  end
  module_function :add
end