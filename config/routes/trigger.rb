# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # triggers
  match api_path + '/triggers',            to: 'triggers#index',   via: :get
  match api_path + '/triggers/:id',        to: 'triggers#show',    via: :get
  match api_path + '/triggers',            to: 'triggers#create',  via: :post
  match api_path + '/triggers/:id',        to: 'triggers#update',  via: :put
  match api_path + '/triggers/:id',        to: 'triggers#destroy', via: :delete

end
