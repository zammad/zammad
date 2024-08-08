# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :checklists, only: %i[index show create update destroy]
  end
end
