# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # upload cache
  match api_path + '/upload_caches/:id',                 to: 'upload_caches#update', via: :post
  match api_path + '/upload_caches/:id',                 to: 'upload_caches#destroy', via: :delete
  match api_path + '/upload_caches/:id/items/:store_id', to: 'upload_caches#remove_item', via: :delete

end
