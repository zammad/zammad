# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # CRUD
  match api_path + '/external_credentials',                    to: 'external_credentials#index',   via: :get
  match api_path + '/external_credentials/:id',                to: 'external_credentials#show',    via: :get
  match api_path + '/external_credentials',                    to: 'external_credentials#create',  via: :post
  match api_path + '/external_credentials/:id',                to: 'external_credentials#update',  via: :put
  match api_path + '/external_credentials/:id',                to: 'external_credentials#destroy', via: :delete

  # callback URL
  match api_path + '/external_credentials/:provider/app_verify',   to: 'external_credentials#app_verify',   via: :post
  match api_path + '/external_credentials/:provider/link_account', to: 'external_credentials#link_account', via: :get
  match api_path + '/external_credentials/:provider/callback',     to: 'external_credentials#callback',     via: :get

end
