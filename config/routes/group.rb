module ExtraRoutes
  def add(map)

    # groups
    map.match '/api/groups',                       :to => 'groups#index',  :via => :get
    map.match '/api/groups/:id',                   :to => 'groups#show',   :via => :get
    map.match '/api/groups',                       :to => 'groups#create', :via => :post
    map.match '/api/groups/:id',                   :to => 'groups#update', :via => :put

  end
  module_function :add
end