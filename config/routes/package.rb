# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # overviews
  match api_path + '/packages',           to: 'packages#index',      via: :get
  match api_path + '/packages',           to: 'packages#install',    via: :post
  match api_path + '/packages',           to: 'packages#uninstall',  via: :delete
  match api_path + '/packages/api',       to: 'packages#update_api', via: :put
  match api_path + '/packages/api',       to: 'packages#install_api', via: :post

end
