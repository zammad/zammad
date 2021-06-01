# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # groups
  match api_path + '/groups',                     to: 'groups#index',   via: :get
  match api_path + '/groups/:id',                 to: 'groups#show',    via: :get
  match api_path + '/groups',                     to: 'groups#create',  via: :post
  match api_path + '/groups/:id',                 to: 'groups#update',  via: :put
  match api_path + '/groups/:id',                 to: 'groups#destroy', via: :delete

end
