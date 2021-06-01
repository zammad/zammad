# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # signatures
  match api_path + '/signatures',             to: 'signatures#index',   via: :get
  match api_path + '/signatures/:id',         to: 'signatures#show',    via: :get
  match api_path + '/signatures',             to: 'signatures#create',  via: :post
  match api_path + '/signatures/:id',         to: 'signatures#update',  via: :put
  match api_path + '/signatures/:id',         to: 'signatures#destroy', via: :delete

end
