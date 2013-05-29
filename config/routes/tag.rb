module ExtraRoutes
  def add(map)

    # links
    map.match '/api/tags',                       :to => 'tags#list', :via => :get
    map.match '/api/tags/add',                   :to => 'tags#add', :via => :get
    map.match '/api/tags/remove',                :to => 'tags#remove', :via => :get

  end
  module_function :add
end
