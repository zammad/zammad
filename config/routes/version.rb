Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/version',           to: 'version#index',      via: :get

end
