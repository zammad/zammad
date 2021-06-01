# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/time_accounting/log/by_ticket/:year/:month',       to: 'time_accountings#by_ticket',       via: :get
  match api_path + '/time_accounting/log/by_customer/:year/:month',     to: 'time_accountings#by_customer',     via: :get
  match api_path + '/time_accounting/log/by_organization/:year/:month', to: 'time_accountings#by_organization', via: :get

end
