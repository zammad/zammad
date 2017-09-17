class Auth0Database < OmniAuth::Strategies::Auth0
  option :name, 'auth0'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_auth0_credentials') || {}
    args[0] = config['client_id']
    args[1] = config['client_secret']
    args[2] = config['site']
    super
  end

end
