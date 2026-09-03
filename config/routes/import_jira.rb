# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # import jira
  match api_path + '/import/jira/url_check',         to: 'import_jira#url_check',         via: :post
  match api_path + '/import/jira/credentials_check',  to: 'import_jira#credentials_check', via: :post
  match api_path + '/import/jira/import_start',        to: 'import_jira#import_start',      via: :post
  match api_path + '/import/jira/import_status',       to: 'import_jira#import_status',     via: :get

end
