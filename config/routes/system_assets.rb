# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/system_assets/:identifier/:timestamp', to: 'system_assets#show', via: :get, as: :system_asset
end
