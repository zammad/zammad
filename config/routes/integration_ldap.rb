# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/ldap/discover',    to: 'integration/ldap#discover',          via: :post
  match api_path + '/integration/ldap/bind',        to: 'integration/ldap#bind',              via: :post
  match api_path + '/integration/ldap/job_try',     to: 'integration/ldap#job_try_index',     via: :get
  match api_path + '/integration/ldap/job_try',     to: 'integration/ldap#job_try_create',    via: :post
  match api_path + '/integration/ldap/job_start',   to: 'integration/ldap#job_start_index',   via: :get
  match api_path + '/integration/ldap/job_start',   to: 'integration/ldap#job_start_create',  via: :post
end
