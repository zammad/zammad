module ExtraRoutes
  def add(map, api_path)

    # links
    map.match api_path + '/tags',                   :to => 'tags#list',   :via => :get
    map.match api_path + '/tags/add',               :to => 'tags#add',    :via => :get
    map.match api_path + '/tags/remove',            :to => 'tags#remove', :via => :get

  end
  module_function :add
end
