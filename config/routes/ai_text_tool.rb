# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ai_text_tools',                     to: 'ai_text_tools#index',     via: :get
  match api_path + '/ai_text_tools/search',              to: 'ai_text_tools#search',    via: %i[get post]
  match api_path + '/ai_text_tools/types',               to: 'ai_text_tools#types',     via: :get
  match api_path + '/ai_text_tools/:id',                 to: 'ai_text_tools#show',      via: :get
  match api_path + '/ai_text_tools',                     to: 'ai_text_tools#create',    via: :post
  match api_path + '/ai_text_tools/:id',                 to: 'ai_text_tools#update',    via: :put
  match api_path + '/ai_text_tools/:id',                 to: 'ai_text_tools#destroy',   via: :delete

end
