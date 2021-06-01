# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do

  # shorter version
  match '/ical',                 to: 'calendar_subscriptions#all',    via: :get
  match '/ical/:object',         to: 'calendar_subscriptions#object', via: :get
  match '/ical/:object/:method', to: 'calendar_subscriptions#object', via: :get

  # wording version
  match '/calendar_subscriptions',                 to: 'calendar_subscriptions#all',    via: :get
  match '/calendar_subscriptions/:object',         to: 'calendar_subscriptions#object', via: :get
  match '/calendar_subscriptions/:object/:method', to: 'calendar_subscriptions#object', via: :get
end
