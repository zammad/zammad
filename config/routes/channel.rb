module ExtraRoutes
  def add(map, api_path)

    # channels
    map.match api_path + '/channels',                       :to => 'channels#index',   :via => :get
    map.match api_path + '/channels/:id',                   :to => 'channels#show',    :via => :get
    map.match api_path + '/channels',                       :to => 'channels#create',  :via => :post
    map.match api_path + '/channels/:id',                   :to => 'channels#update',  :via => :put
    map.match api_path + '/channels/:id',                   :to => 'channels#destroy', :via => :delete

  end
  module_function :add
end