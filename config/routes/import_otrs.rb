# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # import otrs
  match api_path + '/import/otrs/url_check',          to: 'import_otrs#url_check',     via: :post
  match api_path + '/import/otrs/import_check',       to: 'import_otrs#import_check',  via: :post
  match api_path + '/import/otrs/import_start',       to: 'import_otrs#import_start',  via: :post
  match api_path + '/import/otrs/import_status',      to: 'import_otrs#import_status', via: :get

end
