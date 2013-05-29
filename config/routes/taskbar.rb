module ExtraRoutes
  def add(map)
    map.match '/api/taskbar',                  :to => 'taskbar#index',  :via => :get
    map.match '/api/taskbar/:id',              :to => 'taskbar#show',   :via => :get
    map.match '/api/taskbar',                  :to => 'taskbar#create', :via => :post
    map.match '/api/taskbar/:id',              :to => 'taskbar#update', :via => :put
    map.match '/api/taskbar/:id',              :to => 'taskbar#destroy',   :via => :delete
  end
  module_function :add
end
