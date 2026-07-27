Rails.application.routes.draw do
  # ... existing routes ...

  namespace :api do
    namespace :guest do
      resources :tickets, only: [] do
        collection do
          post :create_incident, action: :create_incident
          post :create_change_request, action: :create_change_request
          post :create_service_request, action: :create_service_request
        end
      end
    end
  end

  # Guest ticket submission pages (no authentication required)
  namespace :guest do
    resources :tickets, only: [:index] do
      collection do
        get :incident
        get :change_request
        get :service_request
      end
    end
  end
end
