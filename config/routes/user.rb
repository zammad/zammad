# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # users
  match api_path + '/users/search',                to: 'users#search',                via: %i[get post option]
  match api_path + '/users/password_reset',        to: 'users#password_reset_send',   via: :post
  match api_path + '/users/password_reset_verify', to: 'users#password_reset_verify', via: :post
  match api_path + '/users/password_change',       to: 'users#password_change',       via: :post
  match api_path + '/users/preferences',           to: 'users#preferences',           via: :put
  match api_path + '/users/out_of_office',         to: 'users#out_of_office',         via: :put
  match api_path + '/users/account',               to: 'users#account_remove',        via: :delete

  match api_path + '/users/import_example',        to: 'users#import_example',        via: :get
  match api_path + '/users/import',                to: 'users#import_start',          via: :post

  match api_path + '/users/avatar',                to: 'users#avatar_new',            via: :post
  match api_path + '/users/avatar',                to: 'users#avatar_list',           via: :get
  match api_path + '/users/avatar',                to: 'users#avatar_destroy',        via: :delete
  match api_path + '/users/avatar/set',            to: 'users#avatar_set_default',    via: :post

  match api_path + '/users/me',                    to: 'users#me',                    via: :get

  match api_path + '/users',                       to: 'users#index',                 via: :get
  match api_path + '/users/:id',                   to: 'users#show',                  via: :get
  match api_path + '/users/history/:id',           to: 'users#history',               via: :get
  match api_path + '/users',                       to: 'users#create',                via: :post
  match api_path + '/users/:id',                   to: 'users#update',                via: :put,    as: 'api_v1_update_user'
  match api_path + '/users/:id',                   to: 'users#destroy',               via: :delete, as: 'api_v1_delete_user'
  match api_path + '/users/image/:hash',           to: 'users#image',                 via: :get

  match api_path + '/users/email_verify',          to: 'users#email_verify',          via: :post
  match api_path + '/users/email_verify_send',     to: 'users#email_verify_send',     via: :post

end
