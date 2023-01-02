# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/gitlab',                to: 'integration/gitlab#query',   via: :post
  match api_path + '/integration/gitlab',                to: 'integration/gitlab#query',   via: :get
  match api_path + '/integration/gitlab/verify',         to: 'integration/gitlab#verify',  via: :post
  match api_path + '/integration/gitlab_ticket_update',  to: 'integration/gitlab#update',  via: :post

end
