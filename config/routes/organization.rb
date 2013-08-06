module ExtraRoutes
  def add(map, api_path)

    # organizations
    map.match api_path + '/organizations',            :to => 'organizations#index',  :via => :get
    map.match api_path + '/organizations/:id',        :to => 'organizations#show',   :via => :get
    map.match api_path + '/organizations',            :to => 'organizations#create', :via => :post
    map.match api_path + '/organizations/:id',        :to => 'organizations#update', :via => :put

  end
  module_function :add
end
