Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # groups
  match api_path + '/online_notifications',                   :to => 'online_notifications#index',         :via => :get
  match api_path + '/online_notifications/:id',               :to => 'online_notifications#update',        :via => :put
  match api_path + '/online_notifications/markAllAsSeen',     :to => 'online_notifications#markAllAsSeen', :via => :post

end