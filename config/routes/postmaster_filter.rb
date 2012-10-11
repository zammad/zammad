module ExtraRoutes
  def add(map)

    # postmaster_filters
    map.match '/api/postmaster_filters',                :to => 'postmaster_filters#index',   :via => :get
    map.match '/api/postmaster_filters/:id',            :to => 'postmaster_filters#show',    :via => :get
    map.match '/api/postmaster_filters',                :to => 'postmaster_filters#create',  :via => :post
    map.match '/api/postmaster_filters/:id',            :to => 'postmaster_filters#update',  :via => :put
    map.match '/api/postmaster_filters/:id',            :to => 'postmaster_filters#destroy', :via => :delete

  end
  module_function :add
end