# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/content_translation/providers/:provider/activate',   to: 'content_translation/providers#activate',   via: :post
  match api_path + '/content_translation/providers/:provider/deactivate', to: 'content_translation/providers#deactivate', via: :post
end
