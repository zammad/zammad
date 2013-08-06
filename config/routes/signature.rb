module ExtraRoutes
  def add(map, api_path)

    # signatures
    map.match api_path + '/signatures',             :to => 'signatures#index',   :via => :get
    map.match api_path + '/signatures/:id',         :to => 'signatures#show',    :via => :get
    map.match api_path + '/signatures',             :to => 'signatures#create',  :via => :post
    map.match api_path + '/signatures/:id',         :to => 'signatures#update',  :via => :put
    map.match api_path + '/signatures/:id',         :to => 'signatures#destroy', :via => :delete

  end
  module_function :add
end