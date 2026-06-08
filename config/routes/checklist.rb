# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :checklists, only: %i[show create update destroy]
    resources :checklist_items, only: %i[create update destroy show] do
      post :create_bulk, on: :collection
    end
    resources :checklist_templates, only: %i[index show create update destroy]
  end
end
