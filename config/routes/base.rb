module ExtraRoutes
  def add(map)

    # base objects
    map.resources :settings,                  :only => [:create, :show, :index, :update]

    # users
    map.resources :users,                     :only => [:create, :show, :index, :update]
    map.match '/users/password_reset',        :to => 'users#password_reset_send'
    map.match '/users/password_reset_verify', :to => 'users#password_reset_verify'

    # groups
    map.resources :groups,                    :only => [:create, :show, :index, :update]

    # roles
    map.resources :roles,                     :only => [:create, :show, :index, :update]

    # organizations
    map.resources :organizations,             :only => [:create, :show, :index, :update]

    # templates
    map.resources :templates

    # links
    map.match '/links',                       :to => 'links#index'
    map.match '/links/add',                   :to => 'links#add'
    map.match '/links/remove',                :to => 'links#remove'

    # overviews
    map.resources :overviews

    # getting_started
    map.match '/getting_started',             :to => 'getting_started#index'

    # rss
    map.match '/rss_fetch',                   :to => 'rss#fetch'
  end
  module_function :add
end