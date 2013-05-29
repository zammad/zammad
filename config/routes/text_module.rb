module ExtraRoutes
  def add(map)

    # roles
    map.match '/api/text_modules',                  :to => 'text_modules#index',    :via => :get
    map.match '/api/text_modules/:id',              :to => 'text_modules#show',     :via => :get
    map.match '/api/text_modules',                  :to => 'text_modules#create',   :via => :post
    map.match '/api/text_modules/:id',              :to => 'text_modules#update',   :via => :put
    map.match '/api/text_modules/:id',              :to => 'text_modules#destroy',  :via => :delete

  end
  module_function :add
end