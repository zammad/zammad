# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :ssl_certificates, only: %i[index create destroy] do
      member do
        get :download
      end
    end
  end
end
