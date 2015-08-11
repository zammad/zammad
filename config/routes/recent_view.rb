Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/recent_view',     to: 'recent_view#index', via: :get
  match api_path + '/recent_view',     to: 'recent_view#create', via: :post
end
