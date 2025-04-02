# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/taskbar',            to: 'taskbar#index',  via: :get
  match api_path + '/taskbar/init',       to: 'taskbar#init',  via: :get
  match api_path + '/taskbar/:id',        to: 'taskbar#show',   via: :get
  match api_path + '/taskbar',            to: 'taskbar#create', via: :post
  match api_path + '/taskbar/:id',        to: 'taskbar#update', via: :put
  match api_path + '/taskbar/:id',        to: 'taskbar#destroy', via: :delete

end
