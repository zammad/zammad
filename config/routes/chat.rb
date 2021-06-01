# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/chats',                to: 'chats#index',   via: :get
  match api_path + '/chats/:id',            to: 'chats#show',    via: :get
  match api_path + '/chats',                to: 'chats#create',  via: :post
  match api_path + '/chats/:id',            to: 'chats#update',  via: :put
  match api_path + '/chats/:id',            to: 'chats#destroy', via: :delete

end
