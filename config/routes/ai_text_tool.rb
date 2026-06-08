# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :ai_text_tools, except: :edit do
      member do
        put 'reset_analytics'
      end

      collection do
        get  'types'
        get  'search'
        post 'search'
      end
    end
  end
end
