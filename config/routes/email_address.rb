module ExtraRoutes
  def add(map)

    # groups
    map.match '/api/email_addresses',                       :to => 'email_addresses#index',  :via => :get
    map.match '/api/email_addresses/:id',                   :to => 'email_addresses#show',   :via => :get
    map.match '/api/email_addresses',                       :to => 'email_addresses#create', :via => :post
    map.match '/api/email_addresses/:id',                   :to => 'email_addresses#update', :via => :put

  end
  module_function :add
end