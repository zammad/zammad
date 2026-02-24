# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module OmniAuth
  module ProviderAvailability
    # Map from auth setting name suffix to strategy class name.
    # Used to determine which providers have their gem installed.
    # NOTE: Keep this in sync with the strategy files in lib/omni_auth/strategies/.
    # Any strategy file added there must also be listed here.
    PROVIDER_STRATEGIES = {
      'twitter'             => 'OmniAuth::Strategies::TwitterDatabase',
      'facebook'            => 'OmniAuth::Strategies::FacebookDatabase',
      'linkedin'            => 'OmniAuth::Strategies::LinkedInDatabase',
      'google_oauth2'       => 'OmniAuth::Strategies::GoogleOauth2Database',
      'github'              => 'OmniAuth::Strategies::GithubDatabase',
      'gitlab'              => 'OmniAuth::Strategies::GitLabDatabase',
      'microsoft_office365' => 'OmniAuth::Strategies::MicrosoftOffice365Database',
      'weibo'               => 'OmniAuth::Strategies::WeiboDatabase',
      'saml'                => 'OmniAuth::Strategies::SamlDatabase',
      'openid_connect'      => 'OmniAuth::Strategies::OidcDatabase',
    }.freeze

    class << self
      attr_reader :available_providers
    end

    # Populate available_providers based on which strategy classes are defined.
    # Called from the omniauth initializer after strategy files are required.
    def self.load!
      @available_providers = PROVIDER_STRATEGIES.filter_map do |name, klass|
        name if Object.const_defined?(klass)
      end.freeze
    end

    def self.available?(provider)
      raise 'OmniAuth::ProviderAvailability.load! has not been called' if @available_providers.nil?

      @available_providers.include?(provider)
    end

    def self.unavailable_settings
      unavailable_providers = PROVIDER_STRATEGIES.keys - available_providers
      unavailable_providers.flat_map { |p| ["auth_#{p}", "auth_#{p}_credentials"] }.to_set
    end
  end
end
