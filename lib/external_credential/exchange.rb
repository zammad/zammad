# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Exchange

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: 'exchange')
    raise Exceptions::UnprocessableEntity, __('No Exchange app configured!') if !external_credential && app_required

    if external_credential
      if credentials[:client_id].blank?
        credentials[:client_id] = external_credential.credentials['client_id']
      end
      if credentials[:client_secret].blank?
        credentials[:client_secret] = external_credential.credentials['client_secret']
      end
      # client_tenant may be empty. Set only if key is nonexistant at all
      if !credentials.key? :client_tenant
        credentials[:client_tenant] = external_credential.credentials['client_tenant']
      end
    end

    raise Exceptions::UnprocessableEntity, __("The required parameter 'client_id' is missing.") if credentials[:client_id].blank?
    raise Exceptions::UnprocessableEntity, __("The required parameter 'client_secret' is missing.") if credentials[:client_secret].blank?

    authorize_url = generate_authorize_url(credentials)

    {
      authorize_url: authorize_url,
    }
  end

  def self.link_account(_request_token, params)

    # return to admin interface if admin Consent is in process and user clicks on "Back to app"
    return "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#system/integration/exchange/error/AADSTS65004" if params[:error_description].present? && params[:error_description].include?('AADSTS65004')

    external_credential = ExternalCredential.find_by(name: 'exchange')
    raise Exceptions::UnprocessableEntity, __('No Exchange app configured!') if !external_credential
    raise Exceptions::UnprocessableEntity, __("The required parameter 'code' is missing.") if !params[:code]

    response = authorize_tokens(external_credential.credentials, params[:code])
    %w[refresh_token access_token expires_in scope token_type id_token].each do |key|
      raise Exceptions::UnprocessableEntity, "No #{key} for authorization request found!" if response[key.to_sym].blank?
    end

    user_data = user_info(response[:id_token])
    raise Exceptions::UnprocessableEntity, __("The user's 'preferred_username' could not be extracted from 'id_token'.") if user_data[:preferred_username].blank?

    config = response.merge(
      user:          user_data[:preferred_username],
      client_id:     external_credential.credentials[:client_id],
      client_secret: external_credential.credentials[:client_secret],
      client_tenant: external_credential.credentials[:client_tenant],
      status:        200,
    )
    Setting.set('exchange_oauth', config)

    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#system/integration/exchange/success/1"
  end

  def self.generate_authorize_url(credentials, scope = 'https://outlook.office365.com/EWS.AccessAsUser.All offline_access openid profile email')
    params = {
      'client_id'     => credentials[:client_id],
      'redirect_uri'  => ExternalCredential.callback_url('exchange'),
      'scope'         => scope,
      'response_type' => 'code',
      'access_type'   => 'offline',
      'prompt'        => credentials[:prompt] || 'login',
    }

    tenant = credentials[:client_tenant].presence || 'common'

    uri = URI::HTTPS.build(
      host:  'login.microsoftonline.com',
      path:  "/#{tenant}/oauth2/v2.0/authorize",
      query: params.to_query
    )

    uri.to_s
  end

  def self.authorize_tokens(credentials, authorization_code)
    uri    = authorize_tokens_uri(credentials[:client_tenant])
    params = authorize_tokens_params(credentials, authorization_code)

    response = Net::HTTP.post_form(uri, params)
    if response.code != 200 && response.body.blank?
      Rails.logger.error "Request failed! (code: #{response.code})"
      raise "Request failed! (code: #{response.code})"
    end

    result = JSON.parse(response.body)
    if result['error'] && response.code != 200
      Rails.logger.error "Request failed! ERROR: #{result['error']} (#{result['error_description']}, params: #{params.to_json})"
      raise "Request failed! ERROR: #{result['error']} (#{result['error_description']})"
    end

    result[:created_at] = Time.zone.now

    result.symbolize_keys
  end

  def self.authorize_tokens_params(credentials, authorization_code)
    {
      client_secret: credentials[:client_secret],
      code:          authorization_code,
      grant_type:    'authorization_code',
      client_id:     credentials[:client_id],
      redirect_uri:  ExternalCredential.callback_url('exchange'),
    }
  end

  def self.authorize_tokens_uri(tenant)
    URI::HTTPS.build(
      host: 'login.microsoftonline.com',
      path: "/#{tenant.presence || 'common'}/oauth2/v2.0/token",
    )
  end

  def self.refresh_token
    config = Setting.get('exchange_oauth')
    return {} if config.blank?
    return config if config[:created_at] >= 50.minutes.ago

    params = refresh_token_params(config)
    uri    = refresh_token_uri(config)

    response = Net::HTTP.post_form(uri, params)
    if response.code != 200 && response.body.blank?
      HttpLog.create(
        direction:     'out',
        facility:      'EWS',
        url:           uri,
        status:        response.code,
        ip:            nil,
        request:       { content: params },
        response:      { content: false },
        method:        'refresh_token',
        created_by_id: 1,
        updated_by_id: 1,
      )

      config_state(response.code)

      Rails.logger.error "Exchange refresh token: Request failed! (code: #{response.code})"
      raise "Request failed! (code: #{response.code})"
    end

    result = JSON.parse(response.body)
    if result['error'] && response.code != 200
      HttpLog.create(
        direction:     'out',
        facility:      'EWS',
        url:           uri,
        status:        response.code,
        ip:            nil,
        request:       { content: params },
        response:      { content: result },
        method:        'refresh_token',
        created_by_id: 1,
        updated_by_id: 1,
      )

      config_state(response.code)

      Rails.logger.error "Exchange refresh token: Request failed! ERROR: #{result['error']} (#{result['error_description']}, params: #{params.to_json})"
      raise "Request failed! ERROR: #{result['error']} (#{result['error_description']})"
    end

    config = config.merge(result.symbolize_keys).merge(
      created_at: Time.zone.now,
      status:     200,
    )

    Setting.set('exchange_oauth', config)

    config
  end

  def self.config_state(status)
    config = Setting.get('exchange_oauth')
    config = config.merge(status: status)
    Setting.set('exchange_oauth', config)
  end

  def self.refresh_token_params(credentials)
    {
      client_id:     credentials[:client_id],
      client_secret: credentials[:client_secret],
      refresh_token: credentials[:refresh_token],
      grant_type:    'refresh_token',
    }
  end

  def self.refresh_token_uri(credentials)
    tenant = credentials[:client_tenant].presence || 'common'

    URI::HTTPS.build(
      host: 'login.microsoftonline.com',
      path: "/#{tenant}/oauth2/v2.0/token",
    )
  end

  def self.user_info(id_token)
    split = id_token.split('.')[1]
    return if split.blank?

    JSON.parse(Base64.decode64(split)).symbolize_keys
  end

end
