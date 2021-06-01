# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # import zendesk
  match api_path + '/import/zendesk/url_check',          to: 'import_zendesk#url_check',         via: :post
  match api_path + '/import/zendesk/credentials_check',  to: 'import_zendesk#credentials_check', via: :post
  match api_path + '/import/zendesk/import_start',       to: 'import_zendesk#import_start',      via: :post
  match api_path + '/import/zendesk/import_status',      to: 'import_zendesk#import_status',     via: :get

end
