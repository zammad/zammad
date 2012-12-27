module ExtraRoutes
  def add(map)

    # overviews
    map.match '/api/packages',                        :to => 'packages#index',   :via => :get
    map.match '/api/packages',                        :to => 'packages#create',  :via => :post

  end
  module_function :add
end