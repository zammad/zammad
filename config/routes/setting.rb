module ExtraRoutes
  def add(map, api_path)

    # base objects
    map.match api_path + '/settings',               :to => 'settings#index',   :via => :get
    map.match api_path + '/settings/:id',           :to => 'settings#show',    :via => :get
    map.match api_path + '/settings',               :to => 'settings#create',  :via => :post
    map.match api_path + '/settings/:id',           :to => 'settings#update',  :via => :put
    map.match api_path + '/settings/:id',           :to => 'settings#destroy', :via => :delete

  end
  module_function :add
end