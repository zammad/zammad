# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # jobs
  match api_path + '/user_devices',            to: 'user_devices#index',   via: :get
  match api_path + '/user_devices/:id',        to: 'user_devices#destroy', via: :delete

end
