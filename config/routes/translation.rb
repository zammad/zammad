# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/translations/push',               to: 'translations#push',  via: :put
  match api_path + '/translations/sync/:locale',       to: 'translations#sync',  via: :get
  match api_path + '/translations/reset',              to: 'translations#reset', via: :post
  match api_path + '/translations/lang/:locale',       to: 'translations#lang',  via: :get
  match api_path + '/translations/admin/lang/:locale', to: 'translations#admin', via: :get

  match api_path + '/translations',              to: 'translations#index',   via: :get
  match api_path + '/translations/:id',          to: 'translations#show',    via: :get
  match api_path + '/translations',              to: 'translations#create',  via: :post
  match api_path + '/translations/:id',          to: 'translations#update',  via: :put
  match api_path + '/translations/:id',          to: 'translations#destroy', via: :delete

end
