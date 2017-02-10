Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/proxy', to: 'proxy#test',   via: :post

end
