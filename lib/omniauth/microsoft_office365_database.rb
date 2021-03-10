class MicrosoftOffice365Database < OmniAuth::Strategies::MicrosoftOffice365
  option :name, 'microsoft_office365'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_microsoft_office365_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    self.class.option :client_options, {
      site:          'https://login.microsoftonline.com',
      authorize_url: "/#{config['app_tenant']}/oauth2/v2.0/authorize",
      token_url:     "/#{config['app_tenant']}/oauth2/v2.0/token",
    }
    super
  end

end
