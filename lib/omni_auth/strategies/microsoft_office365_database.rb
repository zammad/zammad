# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'jwt'

class OmniAuth::Strategies::MicrosoftOffice365Database < OmniAuth::Strategies::MicrosoftOffice365
  option :name, 'microsoft_office365'

  def initialize(app, *args, &)

    # database lookup
    config  = Setting.get('auth_microsoft_office365_credentials') || {}
    args[0] = config['app_id']
    args[1] = config['app_secret']
    tenant  = config['app_tenant'].presence || 'common'
    @microsoft_cloud = configured_cloud(config['cloud'])

    super

    @options[:client_options][:site] = "https://#{@microsoft_cloud.login_host}"
    @options[:client_options][:authorize_url] = "/#{tenant}/oauth2/v2.0/authorize"
    @options[:client_options][:token_url]     = "/#{tenant}/oauth2/v2.0/token"

    # Override the gem's DEFAULT_SCOPE ("openid User.Read Contacts.Read") to drop
    # the Contacts.Read permission. Setting the scope option here makes the gem
    # skip its `params[:scope] ||= DEFAULT_SCOPE` fallback.
    @options[:scope] = "openid #{@microsoft_cloud.graph_scope('User.Read')}"
  end

  def request_phase
    return fail!(:invalid_cloud, @cloud_configuration_error) if @cloud_configuration_error

    super
  end

  def callback_phase
    return fail!(:invalid_cloud, @cloud_configuration_error) if @cloud_configuration_error

    super
  end

  def raw_info
    @raw_info ||= access_token.get("#{microsoft_cloud.graph_base_url}me").parsed
  end

  # The gem's raw_info only calls the Graph /me REST endpoint, which never
  # carries ID token claims such as "xms_edov" (Microsoft's "Email Domain Owner
  # Verified" claim, the recommended signal for safely trusting an email
  # address from a multi-tenant "/common" app registration). We already
  # request the "openid" scope, so the ID token is returned alongside the
  # access token - decode it and expose its claims as their own extra key
  # (OmniAuth merges each ancestor's "extra" block automatically, so this
  # doesn't need to - and, being defined at the class body level rather than
  # inside a regular method, *can't* - call super) for
  # Authorization::Provider::MicrosoftOffice365#email_verified? to read.
  extra do
    id_token = access_token.params['id_token']
    id_token.present? ? { 'id_token_claims' => JWT.decode(id_token, nil, false).first } : {}
  rescue JWT::DecodeError => e
    Rails.logger.warn { "Failed to decode MS365 ID token: #{e.message}" }
    {}
  end

  private

  def configured_cloud(name)
    MicrosoftCloud.new(name)
  rescue ArgumentError => e
    @cloud_configuration_error = e
    MicrosoftCloud.new
  end

  def microsoft_cloud
    @microsoft_cloud ||= MicrosoftCloud.new
  end

  def avatar_file
    photo = access_token.get("#{microsoft_cloud.graph_base_url}me/photo/$value")
    ext = photo.content_type.sub('image/', '')

    Tempfile.new(['avatar', ".#{ext}"]).tap do |file|
      file.binmode
      file.write(photo.body)
      file.rewind
    end
  rescue ::OAuth2::Error => e
    return nil if e.response.status == 404
    return nil if e.code.is_a?(Hash) && e.code['code'] == 'GetUserPhoto' && e.code['message'].to_s.include?('not supported')

    raise
  end
end
