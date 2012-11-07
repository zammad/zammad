module ExtraRoutes
  def add(map)

    # links
    map.match '/api/links',                       :to => 'links#index'
    map.match '/api/links/add',                   :to => 'links#add'
    map.match '/api/links/remove',                :to => 'links#remove'

  end
  module_function :add
end