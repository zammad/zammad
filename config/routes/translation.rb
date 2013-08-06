module ExtraRoutes
  def add(map, api_path)
    map.match api_path + '/translations',              :to => 'translations#index',   :via => :get
    map.match api_path + '/translations/:id',          :to => 'translations#show',    :via => :get
    map.match api_path + '/translations',              :to => 'translations#create',  :via => :post
    map.match api_path + '/translations/:id',          :to => 'translations#update',  :via => :put
    map.match api_path + '/translations/:id',          :to => 'translations#destroy', :via => :delete

    map.match api_path + '/translations/lang/:locale', :to => 'translations#load',    :via => :get
  end
  module_function :add
end
