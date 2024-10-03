# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :checklists, only: %i[index show create update destroy] do
      collection do
        get 'by_ticket/:ticket_id', to: 'checklists#show_by_ticket'
      end
    end

    resources :checklist_items, only: %i[create update destroy show]
    resources :checklist_templates, only: %i[index show create update destroy]
  end
end
