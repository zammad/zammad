# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Explicitly load these files rather than relying on Zeitwerk autoloading.
# OmniAuth is a cuckoo namespace (defined by the omniauth gem), so Zeitwerk
# cannot set up autoloads under it reliably. Strategy files are also in the
# Zeitwerk ignore list. Each file rescues LoadError when its provider gem is absent.
require Rails.root.join('lib/omni_auth/provider_availability')
Rails.root.glob('lib/omni_auth/strategies/*.rb').each { |f| require f }

OmniAuth::ProviderAvailability.load!

Rails.application.config.middleware.use OmniAuth::Builder do

  # twitter database connect
  if OmniAuth::ProviderAvailability.available?('twitter')
    provider :twitter_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
      client_options: {
        authorize_path: '/oauth/authorize',
        site:           'https://api.twitter.com',
      }
    }
  end

  # facebook database connect
  if OmniAuth::ProviderAvailability.available?('facebook')
    provider :facebook_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'
  end

  # linkedin database connect
  if OmniAuth::ProviderAvailability.available?('linkedin')
    provider :linked_in_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'
  end

  # google database connect
  if OmniAuth::ProviderAvailability.available?('google_oauth2')
    provider :google_oauth2_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', access_type: 'online', prompt: ''
  end

  # github database connect
  if OmniAuth::ProviderAvailability.available?('github')
    provider :github_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'
  end

  # gitlab database connect
  if OmniAuth::ProviderAvailability.available?('gitlab')
    provider :git_lab_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
      client_options: {
        site:          'https://not_change_will_be_set_by_database',
        authorize_url: '/oauth/authorize',
        token_url:     '/oauth/token'
      },
      scope:          'read_user',
    }
  end

  # microsoft_office365 database connect
  if OmniAuth::ProviderAvailability.available?('microsoft_office365')
    provider :microsoft_office365_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'
  end

  # weibo database connect
  if OmniAuth::ProviderAvailability.available?('weibo')
    provider :weibo_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'
  end

  # saml database connect
  if OmniAuth::ProviderAvailability.available?('saml')
    provider :saml_database
  end

  # openid_connect database connect
  if OmniAuth::ProviderAvailability.available?('openid_connect')
    provider :oidc_database
  end
end

# This fixes issue #1642 and is required for setups in which Zammad is used
# with a reverse proxy (like e.g. NGINX) handling the HTTPS stuff.
# This leads to the generation of a wrong redirect_uri because Rack detects a
# HTTP request which breaks OAuth2.
OmniAuth.config.full_host = proc {
  "#{Setting.get('http_type')}://#{Setting.get('fqdn')}"
}

OmniAuth.config.logger = Rails.logger
