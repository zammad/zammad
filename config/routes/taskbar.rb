module ExtraRoutes
  def add(map, api_path)
    map.match api_path + '/taskbar',            :to => 'taskbar#index',  :via => :get
    map.match api_path + '/taskbar/:id',        :to => 'taskbar#show',   :via => :get
    map.match api_path + '/taskbar',            :to => 'taskbar#create', :via => :post
    map.match api_path + '/taskbar/:id',        :to => 'taskbar#update', :via => :put
    map.match api_path + '/taskbar/:id',        :to => 'taskbar#destroy',:via => :delete
  end
  module_function :add
end
