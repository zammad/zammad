Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # email helper
  match api_path + '/channels/email_index',           to: 'channels#email_index',         via: :get
  match api_path + '/channels/email_probe',           to: 'channels#email_probe',         via: :post
  match api_path + '/channels/email_outbound',        to: 'channels#email_outbound',      via: :post
  match api_path + '/channels/email_inbound',         to: 'channels#email_inbound',       via: :post
  match api_path + '/channels/email_verify',          to: 'channels#email_verify',        via: :post
  match api_path + '/channels/email_notification',    to: 'channels#email_notification',  via: :post

  # twitter helper
  match api_path + '/channels/twitter_index',         to: 'channels#twitter_index',       via: :get
  match api_path + '/channels/twitter_verify/:id',    to: 'channels#twitter_verify',      via: :post

  # channels
  match api_path + '/channels/group/:id',             to: 'channels#group_update',        via: :post
  match api_path + '/channels/:id',                   to: 'channels#destroy',             via: :delete

end
