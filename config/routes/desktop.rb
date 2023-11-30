# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  get '/desktop', to: 'desktop#index'
  get '/desktop/*path', to: 'desktop#index'
end
