module ExtraRoutes
  def add(map, api_path)

    # groups
    map.match api_path + '/groups',                     :to => 'groups#index',  :via => :get
    map.match api_path + '/groups/:id',                 :to => 'groups#show',   :via => :get
    map.match api_path + '/groups',                     :to => 'groups#create', :via => :post
    map.match api_path + '/groups/:id',                 :to => 'groups#update', :via => :put

  end
  module_function :add
end