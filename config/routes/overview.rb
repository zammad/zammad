# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # overviews
  match api_path + '/overviews',            to: 'overviews#index',   via: :get
  match api_path + '/overviews/:id',        to: 'overviews#show',    via: :get
  match api_path + '/overviews',            to: 'overviews#create',  via: :post
  match api_path + '/overviews/:id',        to: 'overviews#update',  via: :put
  match api_path + '/overviews/:id',        to: 'overviews#destroy', via: :delete
  match api_path + '/overviews_prio',       to: 'overviews#prio',    via: :post

end
