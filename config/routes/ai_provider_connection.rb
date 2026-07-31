# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ai/provider_connections',                  to: 'ai/provider_connections#index',          via: :get
  match api_path + '/ai/provider_connections/search',           to: 'ai/provider_connections#search',         via: %i[get post]
  match api_path + '/ai/provider_connections/:id',              to: 'ai/provider_connections#show',           via: :get
  match api_path + '/ai/provider_connections',                  to: 'ai/provider_connections#create',         via: :post
  match api_path + '/ai/provider_connections/:id',              to: 'ai/provider_connections#update',         via: :put
  match api_path + '/ai/provider_connections/:id',              to: 'ai/provider_connections#destroy',        via: :delete
  match api_path + '/ai/provider_connections/:id/set_default',  to: 'ai/provider_connections#set_default',    via: :put
end
