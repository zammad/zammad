# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # macros
  match api_path + '/macros',         to: 'macros#index',   via: :get
  match api_path + '/macros/:id',     to: 'macros#show',    via: :get
  match api_path + '/macros',         to: 'macros#create',  via: :post
  match api_path + '/macros/:id',     to: 'macros#update',  via: :put
  match api_path + '/macros/:id',     to: 'macros#destroy', via: :delete

end
