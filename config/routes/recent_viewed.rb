Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/recent_viewed',     :to => 'recent_viewed#recent_viewed', :via => :get
end