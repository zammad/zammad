# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

if !Rails.env.production?
  Zammad::Application.routes.draw do
    get '/tests_:name', to: 'tests#show'

    match '/tests/wait/:sec',                   to: 'tests#wait',                       via: :get
    match '/tests/raised_exception',            to: 'tests#error_raised_exception',     via: :get
  end
end
