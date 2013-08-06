module ExtraRoutes
  def add(map, api_path)

    # networkss
    map.match api_path + '/networks',           :to => 'networks#index',  :via => :get
    map.match api_path + '/networks/:id',       :to => 'networks#show',   :via => :get
    map.match api_path + '/networks',           :to => 'networks#create', :via => :post
    map.match api_path + '/networks/:id',       :to => 'networks#update', :via => :put
    map.match api_path + '/networks/:id',       :to => 'networks#destroy',:via => :delete

  end
  module_function :add
end