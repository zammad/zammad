# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/system_report', to: 'system_report#index', via: :get
  match api_path + '/system_report/download', to: 'system_report#download', via: :get
  match api_path + '/system_report/plugins', to: 'system_report#plugins', via: :get
end
