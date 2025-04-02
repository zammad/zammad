# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/pgp',                  to: 'integration/pgp#search',       via: :post
  match api_path + '/integration/pgp/status',           to: 'integration/pgp#status',       via: :get
  match api_path + '/integration/pgp/key',              to: 'integration/pgp#key_list',     via: :get
  match api_path + '/integration/pgp/key/:id',          to: 'integration/pgp#key_show',     via: :get
  match api_path + '/integration/pgp/key',              to: 'integration/pgp#key_add',      via: :post
  match api_path + '/integration/pgp/key/:id',          to: 'integration/pgp#key_delete',   via: :delete
  match api_path + '/integration/pgp/key_download/:id', to: 'integration/pgp#key_download', via: :get
end
