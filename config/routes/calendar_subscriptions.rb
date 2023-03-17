# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do

  # shorter version
  match '/ical',                 to: 'calendar_subscriptions#all',    via: %i[get propfind]
  match '/ical/:object',         to: 'calendar_subscriptions#object', via: %i[get propfind]
  match '/ical/:object/:method', to: 'calendar_subscriptions#object', via: %i[get propfind]

  # wording version
  match '/calendar_subscriptions',                 to: 'calendar_subscriptions#all',    via: %i[get propfind]
  match '/calendar_subscriptions/:object',         to: 'calendar_subscriptions#object', via: %i[get propfind]
  match '/calendar_subscriptions/:object/:method', to: 'calendar_subscriptions#object', via: %i[get propfind]
end
