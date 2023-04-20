# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  match '/graphql', to: 'graphql#execute', via: %i[options post]
end
