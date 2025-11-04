# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  scope api_path do
    resources :ai_assistance, only: [] do
      collection do
        post 'text_tools/:id', action: :text_tools
      end
    end
  end
end
