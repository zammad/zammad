# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # getting_started
  match api_path + '/getting_started',                    to: 'getting_started#index',              via: :get
  match api_path + '/getting_started/auto_wizard/:token', to: 'getting_started#auto_wizard_admin',  via: :get
  match api_path + '/getting_started/auto_wizard',        to: 'getting_started#auto_wizard_admin',  via: :get
  match api_path + '/getting_started/base',               to: 'getting_started#base',               via: :post

end
