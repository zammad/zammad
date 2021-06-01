# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_twitter',           to: 'channels_twitter#index',            via: :get
  match api_path + '/channels_twitter/:id',       to: 'channels_twitter#update',           via: :post
  match api_path + '/channels_twitter_disable',   to: 'channels_twitter#disable',          via: :post
  match api_path + '/channels_twitter_enable',    to: 'channels_twitter#enable',           via: :post
  match api_path + '/channels_twitter',           to: 'channels_twitter#destroy',          via: :delete
  match api_path + '/channels_twitter_webhook',   to: 'channels_twitter#webhook_verify',   via: :get
  match api_path + '/channels_twitter_webhook',   to: 'channels_twitter#webhook_incoming', via: :post

end
