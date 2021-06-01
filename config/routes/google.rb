# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_google',                        to: 'channels_google#index',              via: :get
  match api_path + '/channels_google_disable',                to: 'channels_google#disable',            via: :post
  match api_path + '/channels_google_enable',                 to: 'channels_google#enable',             via: :post
  match api_path + '/channels_google',                        to: 'channels_google#destroy',            via: :delete
  match api_path + '/channels_google_group/:id',              to: 'channels_google#group',              via: :post
  match api_path + '/channels_google_inbound/:id',            to: 'channels_google#inbound',            via: :post
  match api_path + '/channels_google_rollback_migration',     to: 'channels_google#rollback_migration', via: :post

end
