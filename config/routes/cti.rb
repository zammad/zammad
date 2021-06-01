# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/cti/log',       to: 'cti#index',     via: :get
  match api_path + '/cti/done/bulk', to: 'cti#done_bulk', via: :post
  match api_path + '/cti/done/:id',  to: 'cti#done',      via: :post

end
