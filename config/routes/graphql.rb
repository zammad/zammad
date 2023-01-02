# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Temporary Hack: only process trigger events if ActionCable is enabled.
# TODO: Remove when this switch is not needed any more.

if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  Zammad::Application.routes.draw do
    match '/graphql', to: 'graphql#execute', via: %i[options post]
  end
end
