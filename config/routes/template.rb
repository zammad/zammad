# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # templates
  match api_path + '/templates',              to: 'templates#index',   via: :get
  match api_path + '/templates/:id',          to: 'templates#show',    via: :get
  match api_path + '/templates',              to: 'templates#create',  via: :post
  match api_path + '/templates/:id',          to: 'templates#update',  via: :put
  match api_path + '/templates/:id',          to: 'templates#destroy', via: :delete

end
