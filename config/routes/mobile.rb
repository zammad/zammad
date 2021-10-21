# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  get '/mobile', to: 'mobile#index'
end
