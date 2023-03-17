# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ldap_sources',                    to: 'ldap_sources#index',   via: :get
  match api_path + '/ldap_sources/:id',                to: 'ldap_sources#show',    via: :get
  match api_path + '/ldap_sources',                    to: 'ldap_sources#create',  via: :post
  match api_path + '/ldap_sources/:id',                to: 'ldap_sources#update',  via: :put
  match api_path + '/ldap_sources/:id',                to: 'ldap_sources#destroy', via: :delete
  match api_path + '/ldap_sources_prio',               to: 'ldap_sources#prio',    via: :post
end
