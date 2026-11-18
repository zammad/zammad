# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/idoit_up',                to: 'integration/idoit_up#query',   via: :post
  match api_path + '/integration/idoit_up',                to: 'integration/idoit_up#query',   via: :get
  match api_path + '/integration/idoit_up/verify',         to: 'integration/idoit_up#verify',  via: :post
  match api_path + '/integration/idoit_up_ticket_update',  to: 'integration/idoit_up#update',  via: :post
  match api_path + '/integration/idoit_up_logo',           to: 'integration/idoit_up#logo',    via: :get
  match api_path + '/integration/idoit_up/sso',            to: 'integration/idoit_up_sso#login',    via: :get
  match api_path + '/integration/idoit_up/identify',       to: 'integration/idoit_up_sso#identify', via: :get

end
