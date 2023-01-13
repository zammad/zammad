# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MicrosoftOffice365Database < OmniAuth::Strategies::MicrosoftOffice365
  option :name, 'microsoft_office365'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_microsoft_office365_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    tenant  = config['app_tenant'].presence || 'common'

    super

    @options[:client_options][:authorize_url] = "/#{tenant}/oauth2/v2.0/authorize"
    @options[:client_options][:token_url]     = "/#{tenant}/oauth2/v2.0/token"
  end

end
