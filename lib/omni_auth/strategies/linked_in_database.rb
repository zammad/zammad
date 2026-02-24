# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

begin
  require 'omniauth-linkedin-oauth2'

  class OmniAuth::Strategies::LinkedInDatabase < OmniAuth::Strategies::LinkedIn
    option :name, 'linkedin'

    def initialize(app, *args, &)

      # database lookup
      config  = Setting.get('auth_linkedin_credentials') || {}
      args[0] = config['app_id']
      args[1] = config['app_secret']
      super
    end

    # Workaround from current omniauth-linkedin gem issue:
    # https://github.com/decioferreira/omniauth-linkedin-oauth2/issues/68
    def token_params
      super.tap do |params|
        params.client_secret = options.client_secret
      end
    end
  end
rescue LoadError => e
  Rails.logger.debug { "OmniAuth: skipping linkedin strategy (#{e.message})" }
end
