Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # search
  match api_path + '/search',           to: 'search#search', via: [:get, :post]

  # search_generic
  match api_path + '/search/:objects',  to: 'search#search_generic', via: [:get, :post]
end
