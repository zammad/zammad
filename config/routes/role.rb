module ExtraRoutes
  def add(map, api_path)

    # roles
    map.match api_path + '/roles',            :to => 'roles#index',   :via => :get
    map.match api_path + '/roles/:id',        :to => 'roles#show',    :via => :get
    map.match api_path + '/roles',            :to => 'roles#create',  :via => :post
    map.match api_path + '/roles/:id',        :to => 'roles#update',  :via => :put

  end
  module_function :add
end