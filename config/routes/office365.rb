Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_office365',                        to: 'channels_office365#index',              via: :get
  match api_path + '/channels_office365_disable',                to: 'channels_office365#disable',            via: :post
  match api_path + '/channels_office365_enable',                 to: 'channels_office365#enable',             via: :post
  match api_path + '/channels_office365',                        to: 'channels_office365#destroy',            via: :delete
  match api_path + '/channels_office365_group/:id',              to: 'channels_office365#group',              via: :post
  match api_path + '/channels_office365_inbound/:id',            to: 'channels_office365#inbound',            via: :post
  match api_path + '/channels_office365_rollback_migration',     to: 'channels_office365#rollback_migration', via: :post

end
