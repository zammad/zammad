# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # two-factor
  match api_path + '/users/:id/two_factor_remove_authentication_method',                     to: 'user/two_factors#two_factor_remove_authentication_method',                 via: :delete
  match api_path + '/users/:id/two_factor_remove_all_authentication_methods',                to: 'user/two_factors#two_factor_remove_all_authentication_methods',            via: :delete
  match api_path + '/users/:id/two_factor_enabled_authentication_methods',                   to: 'user/two_factors#two_factor_enabled_authentication_methods',               via: :get
  match api_path + '/users/two_factor_personal_configuration',                               to: 'user/two_factors#two_factor_personal_configuration',                       via: :get
  match api_path + '/users/two_factor_authentication_method_initiate_configuration/:method', to: 'user/two_factors#two_factor_authentication_method_initiate_configuration', via: :get
  match api_path + '/users/two_factor_authentication_method_configuration/:method',          to: 'user/two_factors#two_factor_authentication_method_configuration',          via: :get
  match api_path + '/users/two_factor_authentication_remove_credentials/:method',            to: 'user/two_factors#two_factor_authentication_remove_credentials',             via: :delete
  match api_path + '/users/two_factor_verify_configuration',                                 to: 'user/two_factors#two_factor_verify_configuration',                         via: :post
  match api_path + '/users/two_factor_default_authentication_method',                        to: 'user/two_factors#two_factor_default_authentication_method',                via: :post
  match api_path + '/users/two_factor_recovery_codes_generate',                              to: 'user/two_factors#two_factor_recovery_codes_generate',                      via: :post

  # users
  match api_path + '/users/search',                to: 'users#search',                via: %i[get post option]
  match api_path + '/users/password_reset',        to: 'users#password_reset_send',   via: :post
  match api_path + '/users/password_reset_verify', to: 'users#password_reset_verify', via: :post
  match api_path + '/users/password_change',       to: 'users#password_change',       via: :post
  match api_path + '/users/password_check',        to: 'users#password_check',        via: :post
  match api_path + '/users/preferences',           to: 'users#preferences',           via: :put
  match api_path + '/users/preferences_notifications_reset', to: 'users#preferences_notifications_reset', via: :post
  match api_path + '/users/out_of_office',         to: 'users#out_of_office',         via: :put
  match api_path + '/users/account',               to: 'users#account_remove',        via: :delete

  match api_path + '/users/import_example',        to: 'users#import_example',        via: :get
  match api_path + '/users/import',                to: 'users#import_start',          via: :post

  match api_path + '/users/avatar',                to: 'users#avatar_new',            via: :post
  match api_path + '/users/avatar',                to: 'users#avatar_list',           via: :get
  match api_path + '/users/avatar',                to: 'users#avatar_destroy',        via: :delete
  match api_path + '/users/avatar/set',            to: 'users#avatar_set_default',    via: :post

  match api_path + '/users/me',                    to: 'users#me',                    via: :get
  match api_path + '/users/after_auth',            to: 'user/after_auth#show',        via: :get

  match api_path + '/users',                       to: 'users#index',                 via: :get
  match api_path + '/users/:id',                   to: 'users#show',                  via: :get
  match api_path + '/users/history/:id',           to: 'users#history',               via: :get
  match api_path + '/users',                       to: 'users#create',                via: :post
  match api_path + '/users/:id',                   to: 'users#update',                via: :put,    as: 'api_v1_update_user'
  match api_path + '/users/:id',                   to: 'users#destroy',               via: :delete, as: 'api_v1_delete_user'
  match api_path + '/users/image/:hash',           to: 'users#image',                 via: :get
  match api_path + '/users/unlock/:id',            to: 'users#unlock',                via: :put

  match api_path + '/users/email_verify',          to: 'users#email_verify',          via: :post
  match api_path + '/users/email_verify_send',     to: 'users#email_verify_send',     via: :post

  match api_path + '/users/admin_password_auth',        to: 'users#admin_password_auth_send',   via: :post
  match api_path + '/users/admin_password_auth_verify', to: 'users#admin_password_auth_verify', via: :post
end
