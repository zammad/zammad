# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  match Rails.configuration.api_path + '/ai/vector_index/sync', to: 'ai/vector_index#sync', via: :post
end
