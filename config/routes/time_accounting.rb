# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # time_accountings
  match api_path + '/time_accountings',            to: 'time_accountings#index',   via: :get
  match api_path + '/time_accountings/:id',        to: 'time_accountings#show',    via: :get
  match api_path + '/time_accountings',            to: 'time_accountings#create',  via: :post
  match api_path + '/time_accountings/:id',        to: 'time_accountings#update',  via: :put
  match api_path + '/time_accountings/:id',        to: 'time_accountings#destroy', via: :delete

  match api_path + '/time_accounting/log/by_activity/:year/:month',     to: 'time_accountings#by_activity',     via: :get
  match api_path + '/time_accounting/log/by_ticket/:year/:month',       to: 'time_accountings#by_ticket',       via: :get
  match api_path + '/time_accounting/log/by_customer/:year/:month',     to: 'time_accountings#by_customer',     via: :get
  match api_path + '/time_accounting/log/by_organization/:year/:month', to: 'time_accountings#by_organization', via: :get

  scope Rails.configuration.api_path do
    resources '/time_accounting/types', controller: 'time_accounting/types', only: %i[index create update]
  end
end
