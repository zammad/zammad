module ExtraRoutes
  def add(map, api_path)

    # overviews
    map.match api_path + '/overviews',            :to => 'overviews#index',   :via => :get
    map.match api_path + '/overviews/:id',        :to => 'overviews#show',    :via => :get
    map.match api_path + '/overviews',            :to => 'overviews#create',  :via => :post
    map.match api_path + '/overviews/:id',        :to => 'overviews#update',  :via => :put
    map.match api_path + '/overviews/:id',        :to => 'overviews#destroy', :via => :delete

  end
  module_function :add
end