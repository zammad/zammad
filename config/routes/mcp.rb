# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  match '/mcp', to: 'mcp#handle',             via: :post,          format: false
  match '/mcp', to: 'mcp#method_not_allowed', via: %i[get delete], format: false
end
