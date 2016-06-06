Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # organizations
  match api_path + '/organizations/search',      to: 'organizations#search',   via: [:get, :post]
  match api_path + '/organizations',             to: 'organizations#index',    via: :get
  match api_path + '/organizations/:id',         to: 'organizations#show',     via: :get
  match api_path + '/organizations',             to: 'organizations#create',   via: :post
  match api_path + '/organizations/:id',         to: 'organizations#update',   via: :put
  match api_path + '/organizations/:id',         to: 'organizations#destroy',  via: :delete
  match api_path + '/organizations/history/:id', to: 'organizations#history',  via: :get

end
