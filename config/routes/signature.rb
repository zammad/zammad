module ExtraRoutes
  def add(map)

    # groups
    map.match '/api/signatures',                       :to => 'signatures#index',   :via => :get
    map.match '/api/signatures/:id',                   :to => 'signatures#show',    :via => :get
    map.match '/api/signatures',                       :to => 'signatures#create',  :via => :post
    map.match '/api/signatures/:id',                   :to => 'signatures#update',  :via => :put
    map.match '/api/signatures/:id',                   :to => 'signatures#destroy', :via => :delete

  end
  module_function :add
end