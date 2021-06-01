# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # slas
  match api_path + '/slas',               to: 'slas#index',   via: :get
  match api_path + '/slas/:id',           to: 'slas#show',    via: :get
  match api_path + '/slas',               to: 'slas#create',  via: :post
  match api_path + '/slas/:id',           to: 'slas#update',  via: :put
  match api_path + '/slas/:id',           to: 'slas#destroy', via: :delete

end
