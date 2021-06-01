# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # postmaster_filters
  match api_path + '/postmaster_filters',         to: 'postmaster_filters#index',   via: :get
  match api_path + '/postmaster_filters/:id',     to: 'postmaster_filters#show',    via: :get
  match api_path + '/postmaster_filters',         to: 'postmaster_filters#create',  via: :post
  match api_path + '/postmaster_filters/:id',     to: 'postmaster_filters#update',  via: :put
  match api_path + '/postmaster_filters/:id',     to: 'postmaster_filters#destroy', via: :delete

end
