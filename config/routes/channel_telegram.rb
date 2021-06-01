# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_telegram',                         to: 'channels_telegram#index',    via: :get
  match api_path + '/channels_telegram',                         to: 'channels_telegram#add',      via: :post
  match api_path + '/channels_telegram/:id',                     to: 'channels_telegram#update',   via: :put
  match api_path + '/channels_telegram_webhook/:callback_token', to: 'channels_telegram#webhook',  via: :post
  match api_path + '/channels_telegram_disable',                 to: 'channels_telegram#disable',  via: :post
  match api_path + '/channels_telegram_enable',                  to: 'channels_telegram#enable',   via: :post
  match api_path + '/channels_telegram',                         to: 'channels_telegram#destroy',  via: :delete

end
