# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # groups
  match api_path + '/email_addresses',                to: 'email_addresses#index',   via: :get
  match api_path + '/email_addresses/:id',            to: 'email_addresses#show',    via: :get
  match api_path + '/email_addresses',                to: 'email_addresses#create',  via: :post
  match api_path + '/email_addresses/:id',            to: 'email_addresses#update',  via: :put
  match api_path + '/email_addresses/:id',            to: 'email_addresses#destroy', via: :delete

end
