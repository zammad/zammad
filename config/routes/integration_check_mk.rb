# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/check_mk/:token',   to: 'integration/check_mk#update',   via: :post, defaults: { format: 'json' }
end
