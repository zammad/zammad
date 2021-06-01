# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/mentions',           to: 'mentions#list',         via: :get
  match api_path + '/mentions',           to: 'mentions#create',       via: :post
  match api_path + '/mentions/:id',       to: 'mentions#destroy',      via: :delete
end
