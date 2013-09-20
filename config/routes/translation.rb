Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/translations',              :to => 'translations#index',   :via => :get
  match api_path + '/translations/:id',          :to => 'translations#show',    :via => :get
  match api_path + '/translations',              :to => 'translations#create',  :via => :post
  match api_path + '/translations/:id',          :to => 'translations#update',  :via => :put
  match api_path + '/translations/:id',          :to => 'translations#destroy', :via => :delete

  match api_path + '/translations/lang/:locale', :to => 'translations#load',    :via => :get
end