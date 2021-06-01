# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/exchange/autodiscover', to: 'integration/exchange#autodiscover',      via: :post
  match api_path + '/integration/exchange/folders',      to: 'integration/exchange#folders',           via: :post
  match api_path + '/integration/exchange/mapping',      to: 'integration/exchange#mapping',           via: :post
  match api_path + '/integration/exchange/job_try',      to: 'integration/exchange#job_try_index',     via: :get
  match api_path + '/integration/exchange/job_try',      to: 'integration/exchange#job_try_create',    via: :post
  match api_path + '/integration/exchange/job_start',    to: 'integration/exchange#job_start_index',   via: :get
  match api_path + '/integration/exchange/job_start',    to: 'integration/exchange#job_start_create',  via: :post
end
