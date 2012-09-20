module ExtraRoutes
  def add(map)

    # links
    map.match '/links',                       :to => 'links#index'
    map.match '/links/add',                   :to => 'links#add'
    map.match '/links/remove',                :to => 'links#remove'

  end
  module_function :add
end