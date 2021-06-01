# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/http_logs',            to: 'http_logs#index',   via: :get
  match api_path + '/http_logs/:facility',  to: 'http_logs#index',   via: :get, constraints: { facility: %r{.*} }
  match api_path + '/http_logs',            to: 'http_logs#create',  via: :post

end
