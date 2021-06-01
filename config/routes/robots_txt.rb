# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  match '/robots.txt', to: 'robots_txt#index', via: :get
end
