# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/smime',                           to: 'integration/smime#search',                   via: :post
  match api_path + '/integration/smime/certificate',               to: 'integration/smime#certificate_add',          via: :post
  match api_path + '/integration/smime/certificate',               to: 'integration/smime#certificate_delete',       via: :delete
  match api_path + '/integration/smime/certificate',               to: 'integration/smime#certificate_list',         via: :get
  match api_path + '/integration/smime/private_key',               to: 'integration/smime#private_key_add',          via: :post
  match api_path + '/integration/smime/private_key',               to: 'integration/smime#private_key_delete',       via: :delete
  match api_path + '/integration/smime/certificate_download/:id',  to: 'integration/smime#certificate_download',     via: :get
  match api_path + '/integration/smime/private_key_download/:id',  to: 'integration/smime#private_key_download',     via: :get
end
