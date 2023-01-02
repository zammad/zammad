# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Temporary Hack: only process trigger events if ActionCable is enabled.
# TODO: Remove when this switch is not needed any more.

if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  Zammad::Application.routes.draw do
    get '/mobile', to: 'mobile#index'
    get '/mobile/sw.js', to: 'mobile#service_worker'
    get '/mobile/manifest.webmanifest', to: 'mobile#manifest'
    get '/mobile/*path', to: 'mobile#index'
  end
end
