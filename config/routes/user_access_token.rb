# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # access token
  match api_path + '/user_access_token',      to: 'user_access_token#index',   via: :get
  match api_path + '/user_access_token',      to: 'user_access_token#create',  via: :post
  match api_path + '/user_access_token/:id',  to: 'user_access_token#destroy', via: :delete

end
