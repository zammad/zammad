class FacebookDatabase < OmniAuth::Strategies::Facebook
  option :name, 'facebook'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_facebook_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    super
  end

end
