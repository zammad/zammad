Zammad::Application.routes.draw do

  # app init
  match '/init', :to => 'init#index', :via => :get
  match '/app',  :to => 'init#index', :via => :get

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'init#index', :via => :get

end