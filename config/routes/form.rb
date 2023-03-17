# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # forms
  match api_path + '/form_submit',      to: 'form#submit',        via: :post
  match api_path + '/form_config',      to: 'form#configuration', via: :post

end
