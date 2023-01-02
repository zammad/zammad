# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # user_overview_sortings
  match api_path + '/user_overview_sortings',            to: 'user/overview_sortings#index',   via: :get
  match api_path + '/user_overview_sortings/:id',        to: 'user/overview_sortings#show',    via: :get
  match api_path + '/user_overview_sortings',            to: 'user/overview_sortings#create',  via: :post
  match api_path + '/user_overview_sortings/:id',        to: 'user/overview_sortings#update',  via: :put
  match api_path + '/user_overview_sortings/:id',        to: 'user/overview_sortings#destroy', via: :delete
  match api_path + '/user_overview_sortings_prio',       to: 'user/overview_sortings#prio',    via: :post
end
