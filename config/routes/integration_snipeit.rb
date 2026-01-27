# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/snipeit',                to: 'integration/snipeit#query',   via: :post
  match api_path + '/integration/snipeit',                to: 'integration/snipeit#query',   via: :get
  match api_path + '/integration/snipeit/verify',         to: 'integration/snipeit#verify',  via: :post
  match api_path + '/integration/snipeit/query',          to: 'integration/snipeit#query',   via: :post
  match api_path + '/integration/snipeit/update',         to: 'integration/snipeit#update',  via: :post
  match api_path + '/integration/snipeit_ticket_update',  to: 'integration/snipeit#update',  via: :post

end
