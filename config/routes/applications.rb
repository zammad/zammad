# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/applications',            to: 'applications#index',   via: :get
  match api_path + '/applications/:id',        to: 'applications#show',    via: :get
  match api_path + '/applications',            to: 'applications#create',  via: :post
  match api_path + '/applications/:id',        to: 'applications#update',  via: :put
  match api_path + '/applications/:id',        to: 'applications#destroy', via: :delete
  match api_path + '/applications/token',      to: 'applications#token',   via: :post

  # oauth2 provider routes
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end
end
