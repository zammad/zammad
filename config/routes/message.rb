# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # messages
  match api_path + '/message_send',           to: 'long_polling#message_send', via: %i[get post]
  match api_path + '/message_receive',        to: 'long_polling#message_receive', via: %i[get post]

end
