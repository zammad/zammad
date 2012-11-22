module ExtraRoutes
  def add(map)

    # omniauth
    map.match '/auth/:provider/callback', :to => 'sessions#create_omniauth'

    # sessions
    map.match '/signin',                  :to => 'sessions#create'
    map.match '/signshow',                :to => 'sessions#show'
    map.match '/signout',                 :to => 'sessions#destroy'

  end
  module_function :add
end