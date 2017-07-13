class MicrosoftOffice365Database < OmniAuth::Strategies::MicrosoftOffice365
  option :name, 'microsoft_office365'

  def initialize(app, *args, &block)

    # database lookup
    config  = Setting.get('auth_microsoft_office365_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    super
  end

end
