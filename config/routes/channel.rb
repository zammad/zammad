module ExtraRoutes
  def add(map)

    # channels
    map.match '/api/channels',                       :to => 'channels#index',   :via => :get
    map.match '/api/channels/:id',                   :to => 'channels#show',    :via => :get
    map.match '/api/channels',                       :to => 'channels#create',  :via => :post
    map.match '/api/channels/:id',                   :to => 'channels#update',  :via => :put
    map.match '/api/channels/:id',                   :to => 'channels#destroy', :via => :delete

  end
  module_function :add
end