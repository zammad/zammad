# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # base objects
  match api_path + '/settings',               to: 'settings#index',         via: :get
  match api_path + '/settings/area/:area',    to: 'settings#index',         via: :get
  match api_path + '/settings/:id',           to: 'settings#show',          via: :get
  match api_path + '/settings',               to: 'settings#create',        via: :post
  match api_path + '/settings/image/:id',     to: 'settings#update_image',  via: :put
  match api_path + '/settings/:id',           to: 'settings#update',        via: :put
  match api_path + '/settings/:id',           to: 'settings#destroy',       via: :delete

end
