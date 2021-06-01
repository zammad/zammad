# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_facebook',            to: 'channels_facebook#index',    via: :get
  match api_path + '/channels_facebook/:id',        to: 'channels_facebook#update',   via: :post
  match api_path + '/channels_facebook_disable',    to: 'channels_facebook#disable',  via: :post
  match api_path + '/channels_facebook_enable',     to: 'channels_facebook#enable',   via: :post
  match api_path + '/channels_facebook',            to: 'channels_facebook#destroy',  via: :delete
end
