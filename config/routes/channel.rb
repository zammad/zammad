Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # email helper
  match api_path + '/channels/email_index',           to: 'channels#email_index',         via: :get
  match api_path + '/channels/email_probe',           to: 'channels#email_probe',         via: :post
  match api_path + '/channels/email_outbound',        to: 'channels#email_outbound',      via: :post
  match api_path + '/channels/email_inbound',         to: 'channels#email_inbound',       via: :post
  match api_path + '/channels/email_verify',          to: 'channels#email_verify',        via: :post
  match api_path + '/channels/email_notification',    to: 'channels#email_notification',  via: :post

  # channels
  match api_path + '/channels/:id',                   to: 'channels#show',    via: :get
  match api_path + '/channels',                       to: 'channels#create',  via: :post
  match api_path + '/channels/:id',                   to: 'channels#update',  via: :put
  match api_path + '/channels/:id',                   to: 'channels#destroy', via: :delete

end
