# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  get '/mobile', to: 'mobile#index'
  get '/mobile/sw.js', to: 'mobile#service_worker'
  get '/mobile/manifest.webmanifest', to: 'mobile#manifest'
  get '/mobile/*path', to: 'mobile#index'
end
