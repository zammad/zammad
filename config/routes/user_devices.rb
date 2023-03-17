# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # jobs
  match api_path + '/user_devices',            to: 'user_devices#index',   via: :get
  match api_path + '/user_devices/:id',        to: 'user_devices#destroy', via: :delete

end
