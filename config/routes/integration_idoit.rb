# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/idoit',                to: 'integration/idoit#query',   via: :post
  match api_path + '/integration/idoit',                to: 'integration/idoit#query',   via: :get
  match api_path + '/integration/idoit/verify',         to: 'integration/idoit#verify',  via: :post
  match api_path + '/integration/idoit_ticket_update',  to: 'integration/idoit#update',  via: :post

end
