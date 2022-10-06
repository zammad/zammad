# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Microsoft365

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: 'microsoft365')
    raise Exceptions::UnprocessableEntity, __('No Microsoft 365 app configured!') if !external_credential && app_required

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
    return "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/microsoft365/error/AADSTS65004" if params[:error_description].present? && params[:error_description].include?('AADSTS65004')

    external_credential = ExternalCredential.find_by(name: 'microsoft365')
    raise Exceptions::UnprocessableEntity, __('No Microsoft 365 app configured!') if !external_credential
    raise Exceptions::UnprocessableEntity, __("The required parameter 'code' is missing.") if !params[:code]

    response = authorize_tokens(external_credential.credentials, params[:code])
    %w[refresh_token access_token expires_in scope token_type id_token].each do |key|
      raise Exceptions::UnprocessableEntity, "No #{key} for authorization request found!" if response[key.to_sym].blank?
    end

    user_data = user_info(response[:id_token])
    raise Exceptions::UnprocessableEntity, __("The user's 'preferred_username' could not be extracted from 'id_token'.") if user_data[:preferred_username].blank?

    channel_options = {
      inbound:  {
        adapter: 'imap',
        options: {
          auth_type: 'XOAUTH2',
          host:      'outlook.office365.com',
          ssl:       'ssl',
          user:      user_data[:preferred_username],
        },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host:           'smtp.office365.com',
          port:           587,
          user:           user_data[:preferred_username],
          authentication: 'xoauth2',
        },
      },
      auth:     response.merge(
        provider:      'microsoft365',
        type:          'XOAUTH2',
        client_id:     external_credential.credentials[:client_id],
        client_secret: external_credential.credentials[:client_secret],
        client_tenant: external_credential.credentials[:client_tenant],
      ),
    }

    if params[:channel_id]
      existing_channel = Channel.where(area: 'Microsoft365::Account').find(params[:channel_id])

      existing_channel.update!(
        options: channel_options,
      )

      existing_channel.refresh_xoauth2!

      return existing_channel
    end

    migrate_channel = nil
    Channel.where(area: 'Email::Account').find_each do |channel|
      next if channel.options.dig(:inbound, :options, :host)&.downcase != 'outlook.office365.com'
      next if channel.options.dig(:outbound, :options, :host)&.downcase != 'smtp.office365.com'
      next if channel.options.dig(:outbound, :options, :user)&.downcase != user_data[:preferred_username].downcase && channel.options.dig(:outbound, :email)&.downcase != user_data[:preferred_username].downcase

      migrate_channel = channel

      break
    end

    if migrate_channel
      channel_options[:inbound][:options][:folder]         = migrate_channel.options[:inbound][:options][:folder]
      channel_options[:inbound][:options][:keep_on_server] = migrate_channel.options[:inbound][:options][:keep_on_server]

      backup = {
        attributes:  {
          area:         migrate_channel.area,
          options:      migrate_channel.options,
          last_log_in:  migrate_channel.last_log_in,
          last_log_out: migrate_channel.last_log_out,
          status_in:    migrate_channel.status_in,
          status_out:   migrate_channel.status_out,
        },
        migrated_at: Time.zone.now,
      }

      migrate_channel.update(
        area:         'Microsoft365::Account',
        options:      channel_options.merge(backup_imap_classic: backup),
        last_log_in:  nil,
        last_log_out: nil,
      )

      return migrate_channel
    end

    email_addresses = [
      {
        realname: "#{Setting.get('product_name')} Support",
        email:    user_data[:preferred_username],
      },
    ]

    email_addresses.each do |email|
      next if !EmailAddress.exists?(email: email[:email])

      raise Exceptions::UnprocessableEntity, "Duplicate email address or email alias #{email[:email]} found!"
    end

    # create channel
    channel = Channel.create!(
      area:          'Microsoft365::Account',
      group_id:      Group.first.id,
      options:       channel_options,
      active:        false,
      created_by_id: 1,
      updated_by_id: 1,
    )

    email_addresses.each do |user_alias|
      EmailAddress.create!(
        channel_id:    channel.id,
        realname:      user_alias[:realname],
        email:         user_alias[:email],
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    channel
  end

  def self.generate_authorize_url(credentials, scope = 'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access openid profile email')
    params = {
      'client_id'     => credentials[:client_id],
      'redirect_uri'  => ExternalCredential.callback_url('microsoft365'),
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
      redirect_uri:  ExternalCredential.callback_url('microsoft365'),
    }
  end

  def self.authorize_tokens_uri(tenant)
    URI::HTTPS.build(
      host: 'login.microsoftonline.com',
      path: "/#{tenant.presence || 'common'}/oauth2/v2.0/token",
    )
  end

  def self.refresh_token(token)
    return token if token[:created_at] >= 50.minutes.ago

    params = refresh_token_params(token)
    uri    = refresh_token_uri(token)

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

    token.merge(result.symbolize_keys).merge(
      created_at: Time.zone.now,
    )
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
