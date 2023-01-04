# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # import kayako
  match api_path + '/import/kayako/url_check',          to: 'import_kayako#url_check',         via: :post
  match api_path + '/import/kayako/credentials_check',  to: 'import_kayako#credentials_check', via: :post
  match api_path + '/import/kayako/import_start',       to: 'import_kayako#import_start',      via: :post
  match api_path + '/import/kayako/import_status',      to: 'import_kayako#import_status',     via: :get

end
