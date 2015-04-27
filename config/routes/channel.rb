Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # channels
  match api_path + '/channels',                       to: 'channels#index',   via: :get
  match api_path + '/channels/:id',                   to: 'channels#show',    via: :get
  match api_path + '/channels',                       to: 'channels#create',  via: :post
  match api_path + '/channels/:id',                   to: 'channels#update',  via: :put
  match api_path + '/channels/:id',                   to: 'channels#destroy', via: :delete

end