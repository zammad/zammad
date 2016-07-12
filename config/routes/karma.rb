Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/karma',   to: 'karma#index', via: :get

end
