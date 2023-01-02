# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/exchange/index',          to: 'integration/exchange#index',             via: :get
  match api_path + '/integration/exchange/oauth',          to: 'integration/exchange#destroy_oauth',     via: :delete
  match api_path + '/integration/exchange/autodiscover',   to: 'integration/exchange#autodiscover',      via: :post
  match api_path + '/integration/exchange/folders',        to: 'integration/exchange#folders',           via: :post
  match api_path + '/integration/exchange/mapping',        to: 'integration/exchange#mapping',           via: :post
  match api_path + '/integration/exchange/job_try',        to: 'integration/exchange#job_try_index',     via: :get
  match api_path + '/integration/exchange/job_try',        to: 'integration/exchange#job_try_create',    via: :post
  match api_path + '/integration/exchange/job_start',      to: 'integration/exchange#job_start_index',   via: :get
  match api_path + '/integration/exchange/job_start',      to: 'integration/exchange#job_start_create',  via: :post
end
