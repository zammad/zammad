# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  match '/robots.txt', to: 'robots_txt#index', via: :get
end
