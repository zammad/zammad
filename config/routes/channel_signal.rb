Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/channels_signal',                         to: 'channels_signal#index',    via: :get
  match api_path + '/channels_signal',                         to: 'channels_signal#add',      via: :post
  match api_path + '/channels_signal/:id',                     to: 'channels_signal#update',   via: :put
  match api_path + '/channels_signal_disable',                 to: 'channels_signal#disable',  via: :post
  match api_path + '/channels_signal_enable',                  to: 'channels_signal#enable',   via: :post
  match api_path + '/channels_signal',                         to: 'channels_signal#destroy',  via: :delete

end
