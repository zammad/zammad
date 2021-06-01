# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_microsoft365',                        to: 'channels_microsoft365#index',              via: :get
  match api_path + '/channels_microsoft365_disable',                to: 'channels_microsoft365#disable',            via: :post
  match api_path + '/channels_microsoft365_enable',                 to: 'channels_microsoft365#enable',             via: :post
  match api_path + '/channels_microsoft365',                        to: 'channels_microsoft365#destroy',            via: :delete
  match api_path + '/channels_microsoft365_group/:id',              to: 'channels_microsoft365#group',              via: :post
  match api_path + '/channels_microsoft365_inbound/:id',            to: 'channels_microsoft365#inbound',            via: :post
  match api_path + '/channels_microsoft365_rollback_migration',     to: 'channels_microsoft365#rollback_migration', via: :post

end
