# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # groups
  match api_path + '/online_notifications',                   to: 'online_notifications#index',            via: :get
  match api_path + '/online_notifications/:id',               to: 'online_notifications#show',             via: :get
  match api_path + '/online_notifications/:id',               to: 'online_notifications#update',           via: :put
  match api_path + '/online_notifications/:id',               to: 'online_notifications#destroy',          via: :delete
  match api_path + '/online_notifications/mark_all_as_read',  to: 'online_notifications#mark_all_as_read', via: :post

end
