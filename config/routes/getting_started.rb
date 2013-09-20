Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # getting_started
  match api_path + '/getting_started',       :to => 'getting_started#index', :via => :get

end