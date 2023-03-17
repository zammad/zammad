# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do

  #
  # API
  #

  concern :has_publishing do
    member do
      post :has_publishing_update, action: :has_publishing_update

      CanBePublished::StateMachine.aasm.events.each do |event|
        post event.name, action: "has_publishing_#{event.name}"
      end
    end
  end

  scope Rails.configuration.api_path do
    resources :knowledge_bases, only: %i[show update] do
      collection do
        post :init
        get  :visible_ids
        post :search,         controller: 'knowledge_base/search'
        get  :recent_answers, controller: 'knowledge_base/answers'

        resources :manage, controller: 'knowledge_base/manage' do
          collection do
            get :init
          end

          member do
            get :server_snippets
            patch :activate, :deactivate, :update_menu_items
          end
        end

        resource :feed_tokens, controller: 'knowledge_base/feed_tokens', only: %i[show update]
      end

      member do
        resource :permissions, controller: 'knowledge_base/permissions', only: %i[update show]

        get ':locale/feed', to: 'knowledge_base/feeds#root', as: :feed
      end

      resources :categories, controller: 'knowledge_base/categories',
                             except:     %i[new edit] do

        member do
          patch :reorder_categories, :reorder_answers

          resource :permissions, controller: 'knowledge_base/permissions', only: %i[update show]

          get ':locale/feed', to: 'knowledge_base/feeds#category', as: :feed
        end

        collection do
          patch :reorder_root_categories
        end
      end

      resources :answers, controller: 'knowledge_base/answers',
                          only:       %i[create update show destroy],
                          concerns:   :has_publishing do

        resources :attachments, controller: 'knowledge_base/answer/attachments', only: %i[create destroy] do
          collection do
            post :clone_to_form
          end
        end
      end
    end
  end

  #
  # Public
  #

  scope :help do
    get '', to: 'knowledge_base/public/categories#forward_root', as: :help_no_locale
    get ':locale', to: 'knowledge_base/public/categories#index', as: :help_root

    get ':locale/:category/feed', to: 'knowledge_base/public/feeds#category', as: :help_category_feed
    get ':locale/feed', to: 'knowledge_base/public/feeds#root', as: :help_root_feed

    get ':locale/tag/:tag', to: 'knowledge_base/public/tags#show', as: :help_tag

    get ':locale/:category', to: 'knowledge_base/public/categories#show', as: :help_category
    get ':locale/:category/:answer', to: 'knowledge_base/public/answers#show', as: :help_answer
  end
end
