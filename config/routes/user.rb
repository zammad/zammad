Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # users
  match api_path + '/users/search',                :to => 'users#search',                :via => [:get, :post]
  match api_path + '/users/password_reset',        :to => 'users#password_reset_send',   :via => :post
  match api_path + '/users/password_reset_verify', :to => 'users#password_reset_verify', :via => :post
  match api_path + '/users/password_change',       :to => 'users#password_change',       :via => :post
  match api_path + '/users/preferences',           :to => 'users#preferences',           :via => :put
  match api_path + '/users/account',               :to => 'users#account_remove',        :via => :delete
  match api_path + '/users',                       :to => 'users#index',                 :via => :get
  match api_path + '/users/:id',                   :to => 'users#show',                  :via => :get
  match api_path + '/users/history/:id',           :to => 'users#history',               :via => :get
  match api_path + '/users',                       :to => 'users#create',                :via => :post
  match api_path + '/users/:id',                   :to => 'users#update',                :via => :put

end