Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/recent_viewed',     :to => 'recent_viewed#index', :via => :get
  match api_path + '/recent_viewed',     :to => 'recent_viewed#create', :via => :post
end