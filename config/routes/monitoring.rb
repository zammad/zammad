# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/monitoring/health_check',         to: 'monitoring#health_check',        via: :get
  match api_path + '/monitoring/status',               to: 'monitoring#status',              via: :get
  match api_path + '/monitoring/amount_check',         to: 'monitoring#amount_check',        via: :get
  match api_path + '/monitoring/token',                to: 'monitoring#token',               via: :post
  match api_path + '/monitoring/restart_failed_jobs',  to: 'monitoring#restart_failed_jobs', via: :post

end
