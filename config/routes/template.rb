module ExtraRoutes
  def add(map, api_path)

    # templates
    map.match api_path + '/templates',              :to => 'templates#index',   :via => :get
    map.match api_path + '/templates/:id',          :to => 'templates#show',    :via => :get
    map.match api_path + '/templates',              :to => 'templates#create',  :via => :post
    map.match api_path + '/templates/:id',          :to => 'templates#update',  :via => :put
    map.match api_path + '/templates/:id',          :to => 'templates#destroy', :via => :delete

  end
  module_function :add
end