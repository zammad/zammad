Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # CRUD
  match api_path + '/external_credentials_twitter',                to: 'external_credentials_twitter#index',   via: :get
  match api_path + '/external_credentials_twitter/:id',            to: 'external_credentials_twitter#show',    via: :get
  match api_path + '/external_credentials_twitter',                to: 'external_credentials_twitter#create',  via: :post
  match api_path + '/external_credentials_twitter/:id',            to: 'external_credentials_twitter#update',  via: :put
  match api_path + '/external_credentials_twitter/:id',            to: 'external_credentials_twitter#destroy', via: :delete

  # callback URL
  match api_path + '/external_credentials_twitter/:name/auth',     to: 'external_credentials_twitter#auth',    via: :get

end
