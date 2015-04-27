Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # text_modules
  match api_path + '/text_modules',           to: 'text_modules#index',    via: :get
  match api_path + '/text_modules/:id',       to: 'text_modules#show',     via: :get
  match api_path + '/text_modules',           to: 'text_modules#create',   via: :post
  match api_path + '/text_modules/:id',       to: 'text_modules#update',   via: :put
  match api_path + '/text_modules/:id',       to: 'text_modules#destroy',  via: :delete

end
