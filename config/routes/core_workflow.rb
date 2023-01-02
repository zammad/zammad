# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # core_workflows
  match api_path + '/core_workflows',            to: 'core_workflows#index',   via: :get
  match api_path + '/core_workflows/:id',        to: 'core_workflows#show',    via: :get
  match api_path + '/core_workflows',            to: 'core_workflows#create',  via: :post
  match api_path + '/core_workflows/:id',        to: 'core_workflows#update',  via: :put
  match api_path + '/core_workflows/:id',        to: 'core_workflows#destroy', via: :delete
  match api_path + '/core_workflows/perform',    to: 'core_workflows#perform',  via: :post
end
