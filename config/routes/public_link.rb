# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # public_links
  match api_path + '/public_links',         to: 'public_links#index',     via: :get
  match api_path + '/public_links/:id',     to: 'public_links#show',      via: :get
  match api_path + '/public_links',         to: 'public_links#create',    via: :post
  match api_path + '/public_links/:id',     to: 'public_links#update',    via: :put
  match api_path + '/public_links/:id',     to: 'public_links#destroy',   via: :delete
  match api_path + '/public_links_prio',    to: 'public_links#prio',      via: :post
end
