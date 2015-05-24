Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # getting_started
  match api_path + '/getting_started',                    to: 'getting_started#index',             via: :get
  match api_path + '/getting_started/auto_wizard/:token', to: 'getting_started#auto_wizard_admin', via: :get
  match api_path + '/getting_started/auto_wizard',        to: 'getting_started#auto_wizard_admin', via: :get
  match api_path + '/getting_started/base',               to: 'getting_started#base',              via: :post
  match api_path + '/getting_started/email_probe',        to: 'getting_started#email_probe',       via: :post
  match api_path + '/getting_started/email_outbound',     to: 'getting_started#email_outbound',    via: :post
  match api_path + '/getting_started/email_inbound',      to: 'getting_started#email_inbound',     via: :post
  match api_path + '/getting_started/email_verify',       to: 'getting_started#email_verify',      via: :post

end
