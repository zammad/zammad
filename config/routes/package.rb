module ExtraRoutes
  def add(map, api_path)

    # overviews
    map.match api_path + '/packages',           :to => 'packages#index',      :via => :get
    map.match api_path + '/packages',           :to => 'packages#install',    :via => :post
    map.match api_path + '/packages',           :to => 'packages#uninstall',  :via => :delete

  end
  module_function :add
end