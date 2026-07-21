# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :audit_logs, only: %i[index show] do
      collection do
        match :search, via: %i[get post]
      end
    end
  end
end
