# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # object_manager
  match api_path + '/object_manager_attributes_list',            to: 'object_manager_attributes#list',    via: :get
  match api_path + '/object_manager_attributes',                 to: 'object_manager_attributes#index',   via: :get
  match api_path + '/object_manager_attributes/:id',             to: 'object_manager_attributes#show',    via: :get
  match api_path + '/object_manager_attributes',                 to: 'object_manager_attributes#create',  via: :post
  match api_path + '/object_manager_attributes/:id',             to: 'object_manager_attributes#update',  via: :put
  match api_path + '/object_manager_attributes/:id',             to: 'object_manager_attributes#destroy', via: :delete
  match api_path + '/object_manager_attributes_discard_changes', to: 'object_manager_attributes#discard_changes', via: :post
  match api_path + '/object_manager_attributes_execute_migrations', to: 'object_manager_attributes#execute_migrations', via: :post

end
