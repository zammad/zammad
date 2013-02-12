module ExtraRoutes
  def add(map)

    # users
    map.match '/api/users/search',                :to => 'users#search',                :via => [:get, :post]
    map.match '/api/users/password_reset',        :to => 'users#password_reset_send',   :via => :post
    map.match '/api/users/password_reset_verify', :to => 'users#password_reset_verify', :via => :post
    map.match '/api/users/password_change',       :to => 'users#password_change',       :via => :post
    map.match '/api/users/preferences',           :to => 'users#preferences',           :via => :put
    map.match '/api/users',                       :to => 'users#index',                 :via => :get
    map.match '/api/users/:id',                   :to => 'users#show',                  :via => :get
    map.match '/api/users',                       :to => 'users#create',                :via => :post
    map.match '/api/users/:id',                   :to => 'users#update',                :via => :put

  end
  module_function :add
end