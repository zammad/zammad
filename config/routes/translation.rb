module ExtraRoutes
  def add(map)
    map.resources :translations
    map.match '/translations/lang/:locale',   :to => 'translations#load'
  end
  module_function :add
end