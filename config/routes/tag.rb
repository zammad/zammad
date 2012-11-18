module ExtraRoutes
  def add(map)

    # links
    map.match '/api/tags',                       :to => 'tags#list'
    map.match '/api/tags/add',                   :to => 'tags#add'
    map.match '/api/tags/remove',                :to => 'tags#remove'

  end
  module_function :add
end