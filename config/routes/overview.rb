module ExtraRoutes
  def add(map)

    # overviews
    map.match '/api/overviews',                       :to => 'overviews#index',   :via => :get
    map.match '/api/overviews/:id',                   :to => 'overviews#show',    :via => :get
    map.match '/api/overviews',                       :to => 'overviews#create',  :via => :post
    map.match '/api/overviews/:id',                   :to => 'overviews#update',  :via => :put
    map.match '/api/overviews/:id',                   :to => 'overviews#destroy', :via => :delete

  end
  module_function :add
end