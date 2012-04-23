Zammad::Application.routes.draw do

  # app init
  match '/init', :to => 'init#index'
  match '/app',  :to => 'init#index'
  
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'init#index'

  # omniauth
  match '/auth/:provider/callback', :to => 'sessions#create_omniauth'

  # base objects
  resources :settings,            :only => [:create, :show, :index, :update]
  resources :users,               :only => [:create, :show, :index, :update]
  match '/users/password_reset',        :to => 'users#password_reset_send'
  match '/users/password_reset_verify', :to => 'users#password_reset_verify'
  resources :groups,              :only => [:create, :show, :index, :update]
  resources :roles,               :only => [:create, :show, :index, :update]
  resources :organizations,       :only => [:create, :show, :index, :update]

  # overviews
  resources :overviews

  # notes
  resources :notes

  # tickets
  resources :channels,            :only => [:create, :show, :index, :update, :destroy]
  resources :ticket_articles,     :only => [:create, :show, :index, :update]
  resources :ticket_priorities,   :only => [:create, :show, :index, :update]
  resources :ticket_states,       :only => [:create, :show, :index, :update]
  resources :tickets,             :only => [:create, :show, :index, :update]
  match '/ticket_full/:id',       :to => 'ticket_overviews#ticket_full'
  match '/ticket_attachment/:id', :to => 'ticket_overviews#ticket_attachment'
  match '/ticket_attachment_new', :to => 'ticket_overviews#ticket_attachment_new'
  match '/ticket_history/:id',    :to => 'ticket_overviews#ticket_history'
  match '/ticket_customer',       :to => 'ticket_overviews#ticket_customer'
  match '/ticket_overviews',      :to => 'ticket_overviews#show'
  match '/activity_stream',       :to => 'ticket_overviews#activity_stream'
  match '/recent_viewed',         :to => 'ticket_overviews#recent_viewed'
  match '/ticket_create',         :to => 'ticket_overviews#ticket_create'
  match '/user_search',           :to => 'ticket_overviews#user_search'

  # networks
  resources :networks,            :only => [:create, :show, :index, :update, :destroy]

  # getting_started
  match '/getting_started',       :to => 'getting_started#index'

  # sessions
  resources :sessions,            :only => [:create, :destroy, :show]
  match '/signin',                :to => 'sessions#create'
  match '/signshow',              :to => 'sessions#show'
  match '/signout',               :to => 'sessions#destroy'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
