Zammad::Application.routes.draw do
    scope Rails.configuration.api_path do
      resources :s3_attachments, only: %i[create, destroy] do
      end
    end
  end
  