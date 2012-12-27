module ExtraRoutes
  def add(map)

    # overviews
    map.match '/api/packages',                        :to => 'packages#index',      :via => :get
    map.match '/api/packages',                        :to => 'packages#install',    :via => :post
    map.match '/api/packages',                        :to => 'packages#uninstall',  :via => :delete

  end
  module_function :add
end