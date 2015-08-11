Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # networkss
  match api_path + '/networks',           to: 'networks#index',  via: :get
  match api_path + '/networks/:id',       to: 'networks#show',   via: :get
  match api_path + '/networks',           to: 'networks#create', via: :post
  match api_path + '/networks/:id',       to: 'networks#update', via: :put
  match api_path + '/networks/:id',       to: 'networks#destroy', via: :delete

end
