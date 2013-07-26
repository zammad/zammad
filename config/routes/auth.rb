module ExtraRoutes
  def add(map)

    # omniauth
    map.match '/auth/:provider/callback', :to => 'sessions#create_omniauth',:via => [:post, :get, :puts, :delete]

    # sso
    map.match '/auth/sso',                :to => 'sessions#create_sso',     :via => [:post, :get]

    # sessions
    map.match '/signin',                  :to => 'sessions#create',         :via => :post
    map.match '/signshow',                :to => 'sessions#show',           :via => :get
    map.match '/signout',                 :to => 'sessions#destroy',        :via => [:get, :delete]

    map.match '/api/sessions',            :to => 'sessions#list',           :via => :get
    map.match '/api/sessions/:id',        :to => 'sessions#delete',         :via => :delete
  end
  module_function :add
end
