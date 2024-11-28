# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # templates
  match api_path + '/templates',              to: 'templates#index',   via: :get
  match api_path + '/templates/search',       to: 'templates#search',  via: %i[get post]
  match api_path + '/templates/:id',          to: 'templates#show',    via: :get
  match api_path + '/templates',              to: 'templates#create',  via: :post
  match api_path + '/templates/:id',          to: 'templates#update',  via: :put
  match api_path + '/templates/:id',          to: 'templates#destroy', via: :delete

end
