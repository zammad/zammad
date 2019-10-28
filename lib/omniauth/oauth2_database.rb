class Oauth2Database < OmniAuth::Strategies::OAuth2
  option :name, 'oauth2'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_oauth2_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    args[2][:client_options] = args[2][:client_options].merge(config.symbolize_keys)
    super
  end

end
