module ExtraRoutes
  def add(map, api_path)

    # omniauth
    map.match '/auth/:provider/callback',       :to => 'sessions#create_omniauth',:via => [:post, :get, :puts, :delete]

    # sso
    map.match '/auth/sso',                      :to => 'sessions#create_sso',     :via => [:post, :get]

    # sessions
    map.match api_path + '/signin',        :to => 'sessions#create',         :via => :post
    map.match api_path + '/signshow',      :to => 'sessions#show',           :via => :get
    map.match api_path + '/signout',       :to => 'sessions#destroy',        :via => [:get, :delete]

    map.match api_path + '/sessions',      :to => 'sessions#list',           :via => :get
    map.match api_path + '/sessions/:id',  :to => 'sessions#delete',         :via => :delete
  end
  module_function :add
end
