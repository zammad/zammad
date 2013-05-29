module ExtraRoutes
  def add(map)

    # links
    map.match '/api/links',             :to => 'links#index',   :via => :get
    map.match '/api/links/add',         :to => 'links#add',     :via => :get
    map.match '/api/links/remove',      :to => 'links#remove',  :via => :get

  end
  module_function :add
end
