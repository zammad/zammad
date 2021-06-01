# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/tags',               to: 'tags#list',         via: :get
  match api_path + '/tags/add',           to: 'tags#add',          via: :post
  match api_path + '/tags/remove',        to: 'tags#remove',       via: :delete
  match api_path + '/tag_search',         to: 'tags#search',       via: :get

  match api_path + '/tag_list',           to: 'tags#admin_list',   via: :get
  match api_path + '/tag_list',           to: 'tags#admin_create', via: :post
  match api_path + '/tag_list/:id',       to: 'tags#admin_rename', via: :put
  match api_path + '/tag_list/:id',       to: 'tags#admin_delete', via: :delete

end
