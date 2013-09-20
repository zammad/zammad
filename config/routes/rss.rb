Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # rss
  match api_path + '/rss_fetch',   :to => 'rss#fetch', :via => :get

end