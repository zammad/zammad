# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ai_agents',                     to: 'ai_agents#index',     via: :get
  match api_path + '/ai_agents/search',              to: 'ai_agents#search',    via: %i[get post]
  match api_path + '/ai_agents/types',               to: 'ai_agents#types',     via: :get
  match api_path + '/ai_agents/:id',                 to: 'ai_agents#show',      via: :get
  match api_path + '/ai_agents',                     to: 'ai_agents#create',    via: :post
  match api_path + '/ai_agents/:id',                 to: 'ai_agents#update',    via: :put
  match api_path + '/ai_agents/:id',                 to: 'ai_agents#destroy',   via: :delete

end
