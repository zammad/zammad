Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # getting_started
  match api_path + '/getting_started',                :to => 'getting_started#index',         :via => :get
  match api_path + '/getting_started/base_fqdn',      :to => 'getting_started#base_fqdn',     :via => :post
  match api_path + '/getting_started/base_outbound',  :to => 'getting_started#base_outbound', :via => :post
  match api_path + '/getting_started/base_inbound',   :to => 'getting_started#base_inbound',  :via => :post

end