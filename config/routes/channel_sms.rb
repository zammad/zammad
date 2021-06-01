# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_sms',                 to: 'channels_sms#index',         via: :get
  match api_path + '/channels_sms/:id',             to: 'channels_sms#show',          via: :get
  match api_path + '/channels_sms',                 to: 'channels_sms#create',        via: :post
  match api_path + '/channels_sms/:id',             to: 'channels_sms#update',        via: :put
  match api_path + '/channels_sms/:id',             to: 'channels_sms#destroy',       via: :delete
  match api_path + '/channels_sms_enable',          to: 'channels_sms#enable',        via: :post
  match api_path + '/channels_sms_disable',         to: 'channels_sms#disable',       via: :post
  match api_path + '/channels_sms',                 to: 'channels_sms#destroy',       via: :delete
  match api_path + '/channels_sms/test',            to: 'channels_sms#test',          via: :post
  match api_path + '/sms_webhook/:token',           to: 'channels_sms#webhook',       via: :get
  match api_path + '/sms_webhook/:token',           to: 'channels_sms#webhook',       via: :post

end
