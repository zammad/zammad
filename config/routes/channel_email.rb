# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_email',                 to: 'channels_email#index',         via: :get
  match api_path + '/channels_email_probe',           to: 'channels_email#probe',         via: :post
  match api_path + '/channels_email_outbound',        to: 'channels_email#outbound',      via: :post
  match api_path + '/channels_email_inbound',         to: 'channels_email#inbound',       via: :post
  match api_path + '/channels_email_verify',          to: 'channels_email#verify',        via: :post
  match api_path + '/channels_email_notification',    to: 'channels_email#notification',  via: :post
  match api_path + '/channels_email_disable',         to: 'channels_email#disable',       via: :post
  match api_path + '/channels_email_enable',          to: 'channels_email#enable',        via: :post
  match api_path + '/channels_email',                 to: 'channels_email#destroy',       via: :delete
  match api_path + '/channels_email_group/:id',       to: 'channels_email#group',         via: :post

end
