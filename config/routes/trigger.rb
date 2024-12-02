# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # triggers
  match api_path + '/triggers',            to: 'triggers#index',   via: :get
  match api_path + '/triggers/search',     to: 'triggers#search',  via: %i[get post]
  match api_path + '/triggers/:id',        to: 'triggers#show',    via: :get
  match api_path + '/triggers',            to: 'triggers#create',  via: :post
  match api_path + '/triggers/:id',        to: 'triggers#update',  via: :put
  match api_path + '/triggers/:id',        to: 'triggers#destroy', via: :delete

end
