Zammad::Application.routes.draw do

  # app init
  match '/init', :to => 'init#index'
  match '/app',  :to => 'init#index'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'init#index'

  # load routes from external files
  dir = File.expand_path('../', __FILE__)
  files = Dir.glob( "#{dir}/routes/*.rb" )
  for file in files
    require file
    ExtraRoutes.add(self)
  end
end
