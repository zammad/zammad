# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/external_data_source/:object/:attribute',  to: 'external_data_source#fetch',   via: :get
  match api_path + '/external_data_source/preview',             to: 'external_data_source#preview', via: :post
end
