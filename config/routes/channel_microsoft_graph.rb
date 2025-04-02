# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  scope api_path do
    resources :channels_admin_microsoft_graph,
              controller: 'channels_admin/microsoft_graph',
              path:       'channels/admin/microsoft_graph',
              only:       %i[index destroy] do
      member do
        post :enable
        post :disable
        get :folders
      end

      collection do
        post 'group/:id', action: :group
        post 'inbound/:id', action: :inbound
        post 'verify/:id', action: :verify
      end
    end
  end
end
