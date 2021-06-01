# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # webhooks
  match api_path + '/webhooks/preview', to: 'webhooks#preview', via: :get
  match api_path + '/webhooks',         to: 'webhooks#index',   via: :get
  match api_path + '/webhooks/:id',     to: 'webhooks#show',    via: :get
  match api_path + '/webhooks',         to: 'webhooks#create',  via: :post
  match api_path + '/webhooks/:id',     to: 'webhooks#update',  via: :put
  match api_path + '/webhooks/:id',     to: 'webhooks#destroy', via: :delete

end
