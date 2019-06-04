Zammad::Application.routes.draw do
  scope Rails.configuration.api_path do
    resources :attachments, only: %i[show destroy create] do
      collection do
        delete 'destroy_form/:form_id', action: :destroy_form
      end
    end
  end
end
