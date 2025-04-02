# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_whatsapp_webhook/:callback_url_uuid', to: 'channels_whatsapp#verify_webhook',  via: :get
  match api_path + '/channels_whatsapp_webhook/:callback_url_uuid', to: 'channels_whatsapp#perform_webhook', via: :post

  scope api_path do
    resources :channels_admin_whatsapp,
              controller: 'channels_admin/whatsapp',
              path:       'channels/admin/whatsapp',
              only:       %i[index create update destroy] do
      member do
        post :enable
        post :disable
      end

      collection do
        post :preload
      end
    end
  end
end
