# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # reports
  match api_path + '/reports/config',              to: 'reports#reporting_config', via: :get
  match api_path + '/reports/generate',            to: 'reports#generate',        via: :post
  match api_path + '/reports/sets',                to: 'reports#sets',            via: %i[post get]

  # report_profiles
  match api_path + '/report_profiles',             to: 'report_profiles#index',   via: :get
  match api_path + '/report_profiles/:id',         to: 'report_profiles#show',    via: :get
  match api_path + '/report_profiles',             to: 'report_profiles#create',  via: :post
  match api_path + '/report_profiles/:id',         to: 'report_profiles#update',  via: :put
  match api_path + '/report_profiles/:id',         to: 'report_profiles#destroy', via: :delete

end
