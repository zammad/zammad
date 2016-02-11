Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/first_steps',          to: 'first_steps#index',   via: :get

end
