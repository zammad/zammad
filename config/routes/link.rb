module ExtraRoutes
  def add(map, api_path)

    # links
    map.match api_path + '/links',             :to => 'links#index',   :via => :get
    map.match api_path + '/links/add',         :to => 'links#add',     :via => :get
    map.match api_path + '/links/remove',      :to => 'links#remove',  :via => :get

  end
  module_function :add
end
