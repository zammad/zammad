# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # text_modules
  match api_path + '/text_modules/import_example', to: 'text_modules#import_example', via: :get
  match api_path + '/text_modules/import',         to: 'text_modules#import_start',   via: :post
  match api_path + '/text_modules',                to: 'text_modules#index',          via: :get
  match api_path + '/text_modules/:id',            to: 'text_modules#show',           via: :get
  match api_path + '/text_modules',                to: 'text_modules#create',         via: :post
  match api_path + '/text_modules/:id',            to: 'text_modules#update',         via: :put
  match api_path + '/text_modules/:id',            to: 'text_modules#destroy',        via: :delete

end
