# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # calendars
  match api_path + '/calendars_init',       to: 'calendars#init',       via: :get
  match api_path + '/calendars/timezones',  to: 'calendars#timezones',  via: :get
  match api_path + '/calendars',            to: 'calendars#index',      via: :get
  match api_path + '/calendars/:id',        to: 'calendars#show',       via: :get
  match api_path + '/calendars',            to: 'calendars#create',     via: :post
  match api_path + '/calendars/:id',        to: 'calendars#update',     via: :put
  match api_path + '/calendars/:id',        to: 'calendars#destroy',    via: :delete

end
