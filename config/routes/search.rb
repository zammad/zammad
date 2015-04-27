Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # search
  match api_path + '/search',        	  to: 'search#search', via: [:get, :post]

  # search_user_org
  match api_path + '/search_user_org',  to: 'search#search_user_org', via: [:get, :post]

end
