# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ai/feature_providers',         to: 'ai/feature_providers#index',   via: :get
  match api_path + '/ai/feature_providers/:id',     to: 'ai/feature_providers#show',    via: :get
  match api_path + '/ai/feature_providers',         to: 'ai/feature_providers#create',  via: :post
  match api_path + '/ai/feature_providers/:id',     to: 'ai/feature_providers#update',  via: :put
  match api_path + '/ai/feature_providers/:id',     to: 'ai/feature_providers#destroy', via: :delete
end
