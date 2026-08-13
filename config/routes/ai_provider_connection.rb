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

  # POST rather than GET, because the credentials to list with travel in the body. With an :id so
  # the stored token can be used when the admin submits the mask sentinel instead of re-typing it,
  # and without one while a connection is still being created.
  match api_path + '/ai/provider_connections/models',           to: 'ai/provider_connections#models',        via: :post
  match api_path + '/ai/provider_connections/:id/models',       to: 'ai/provider_connections#models',        via: :post

  # Same reasoning for the metadata of one embedding model, which the dialog asks for where the
  # model listing could not size it.
  match api_path + '/ai/provider_connections/embedding_metadata',     to: 'ai/provider_connections#embedding_metadata', via: :post
  match api_path + '/ai/provider_connections/:id/embedding_metadata', to: 'ai/provider_connections#embedding_metadata', via: :post
end
