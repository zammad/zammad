# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # ticket shared drafts

  resource api_path + '/tickets/:ticket_id/shared_draft', controller: 'ticket_shared_draft_zoom', except: %w[new edit create] do
    collection do
      post :import_attachments, as: nil
    end
  end

  resources api_path + '/tickets/shared_drafts',           controller: 'tickets_shared_draft_starts', except: %w[new edit] do
    member do
      post :import_attachments, as: nil
    end
  end

  # tickets
  match api_path + '/tickets/search',                                to: 'tickets#search',            via: %i[get post]
  match api_path + '/tickets/selector',                              to: 'tickets#selector',          via: :post
  match api_path + '/tickets',                                       to: 'tickets#index',             via: :get
  match api_path + '/tickets/:id',                                   to: 'tickets#show',              via: :get
  match api_path + '/tickets',                                       to: 'tickets#create',            via: :post
  match api_path + '/tickets/:id',                                   to: 'tickets#update',            via: :put
  match api_path + '/tickets/:id',                                   to: 'tickets#destroy',           via: :delete
  match api_path + '/tickets/mass_macro',                            to: 'tickets_mass#macro',        via: :post
  match api_path + '/tickets/mass_update',                           to: 'tickets_mass#update',       via: :post
  match api_path + '/ticket_create',                                 to: 'tickets#ticket_create',     via: :get
  match api_path + '/ticket_split',                                  to: 'tickets#ticket_split',      via: :get
  match api_path + '/ticket_history/:id',                            to: 'tickets#ticket_history',    via: :get
  match api_path + '/ticket_customer',                               to: 'tickets#ticket_customer',   via: :get
  match api_path + '/ticket_related/:ticket_id',                     to: 'tickets#ticket_related',    via: :get
  match api_path + '/ticket_recent',                                 to: 'tickets#ticket_recent',     via: :get
  match api_path + '/ticket_merge/:source_ticket_id/:target_ticket_number', to: 'tickets#ticket_merge', via: :put
  match api_path + '/ticket_stats',                                  to: 'tickets#stats',             via: %i[get post]

  # ticket overviews
  match api_path + '/ticket_overview',                               to: 'ticket_overviews#data',     via: :get
  match api_path + '/ticket_overviews',                              to: 'ticket_overviews#show',     via: :get

  # ticket priority
  match api_path + '/ticket_priorities',                             to: 'ticket_priorities#index',   via: :get
  match api_path + '/ticket_priorities/:id',                         to: 'ticket_priorities#show',    via: :get
  match api_path + '/ticket_priorities',                             to: 'ticket_priorities#create',  via: :post
  match api_path + '/ticket_priorities/:id',                         to: 'ticket_priorities#update',  via: :put
  match api_path + '/ticket_priorities/:id',                         to: 'ticket_priorities#destroy', via: :delete

  # ticket state
  match api_path + '/ticket_states',                                 to: 'ticket_states#index',       via: :get
  match api_path + '/ticket_states/:id',                             to: 'ticket_states#show',        via: :get
  match api_path + '/ticket_states',                                 to: 'ticket_states#create',      via: :post
  match api_path + '/ticket_states/:id',                             to: 'ticket_states#update',      via: :put
  match api_path + '/ticket_states/:id',                             to: 'ticket_states#destroy',     via: :delete

  # ticket articles
  match api_path + '/ticket_articles',                               to: 'ticket_articles#index',           via: :get
  match api_path + '/ticket_articles/:id',                           to: 'ticket_articles#show',            via: :get
  match api_path + '/ticket_articles/by_ticket/:id',                 to: 'ticket_articles#index_by_ticket', via: :get
  match api_path + '/ticket_articles',                               to: 'ticket_articles#create',          via: :post
  match api_path + '/ticket_articles/:id',                           to: 'ticket_articles#update',          via: :put
  match api_path + '/ticket_articles/:id',                           to: 'ticket_articles#destroy',     via: :delete
  match api_path + '/ticket_attachment/:ticket_id/:article_id/:id',  to: 'ticket_articles#attachment',      via: :get
  match api_path + '/ticket_attachment_upload_clone_by_article/:article_id', to: 'ticket_articles#ticket_attachment_upload_clone_by_article', via: :post
  match api_path + '/ticket_article_plain/:id',                      to: 'ticket_articles#article_plain',   via: :get
  match api_path + '/ticket_articles/:id/retry_security_process',    to: 'ticket_articles#retry_security_process', via: :post
end
