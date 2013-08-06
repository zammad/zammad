module ExtraRoutes
  def add(map, api_path)

    # slas
    map.match api_path + '/slas',               :to => 'slas#index',   :via => :get
    map.match api_path + '/slas/:id',           :to => 'slas#show',    :via => :get
    map.match api_path + '/slas',               :to => 'slas#create',  :via => :post
    map.match api_path + '/slas/:id',           :to => 'slas#update',  :via => :put
    map.match api_path + '/slas/:id',           :to => 'slas#destroy', :via => :delete

  end
  module_function :add
end