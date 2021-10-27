# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  match '/graphql', to: 'graphql#execute', via: %i[options post]
end
