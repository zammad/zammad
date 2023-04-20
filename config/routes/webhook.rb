# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # webhooks (custom) payload replacements
  match api_path + '/webhooks/payload/replacements', to: 'webhooks#replacements', via: :get

  # webhooks
  match api_path + '/webhooks/preview',     to: 'webhooks#preview', via: :get
  match api_path + '/webhooks/pre_defined', to: 'webhooks#pre_defined_webhooks', via: :get
  match api_path + '/webhooks',             to: 'webhooks#index',   via: :get
  match api_path + '/webhooks/:id',         to: 'webhooks#show',    via: :get
  match api_path + '/webhooks',             to: 'webhooks#create',  via: :post
  match api_path + '/webhooks/:id',         to: 'webhooks#update',  via: :put
  match api_path + '/webhooks/:id',         to: 'webhooks#destroy', via: :delete
end
