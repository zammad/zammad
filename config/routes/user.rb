module ExtraRoutes
  def add(map, api_path)

    # users
    map.match api_path + '/users/search',                :to => 'users#search',                :via => [:get, :post]
    map.match api_path + '/users/password_reset',        :to => 'users#password_reset_send',   :via => :post
    map.match api_path + '/users/password_reset_verify', :to => 'users#password_reset_verify', :via => :post
    map.match api_path + '/users/password_change',       :to => 'users#password_change',       :via => :post
    map.match api_path + '/users/preferences',           :to => 'users#preferences',           :via => :put
    map.match api_path + '/users/account',               :to => 'users#account_remove',        :via => :delete
    map.match api_path + '/users',                       :to => 'users#index',                 :via => :get
    map.match api_path + '/users/:id',                   :to => 'users#show',                  :via => :get
    map.match api_path + '/users',                       :to => 'users#create',                :via => :post
    map.match api_path + '/users/:id',                   :to => 'users#update',                :via => :put

  end
  module_function :add
end