# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::MicrosoftBase < ExternalCredential::Base::ChannelXoauth2
  def self.provider_name
    name.demodulize.underscore
  end

  def self.error_missing_app_configuration
    raise NotImplementedError
  end

  def self.authorize_scope
    raise NotImplementedError
  end

  def self.channel_options_inbound(user_data, account_data)
    raise NotImplementedError
  end

  def self.channel_options_outbound(user_data, account_data)
    raise NotImplementedError
  end

  def self.channel_migration_possible?
    false
  end

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: provider_name)
    raise Exceptions::UnprocessableEntity, error_missing_app_configuration if !external_credential && app_required

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
    return "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/#{provider_name}/error/AADSTS65004" if params[:error_description].present? && params[:error_description].include?('AADSTS65004')

    external_credential = ExternalCredential.find_by(name: provider_name)
    raise Exceptions::UnprocessableEntity, error_missing_app_configuration if !external_credential
    raise Exceptions::UnprocessableEntity, __("The required parameter 'code' is missing.") if !params[:code]

    response = authorize_tokens(external_credential.credentials, params[:code])
    %w[refresh_token access_token expires_in scope token_type id_token].each do |key|
      raise Exceptions::UnprocessableEntity, "No #{key} for authorization request found!" if response[key.to_sym].blank?
    end

    user_data = user_info(response[:id_token])
    raise Exceptions::UnprocessableEntity, __("The user's 'preferred_username' could not be extracted from 'id_token'.") if user_data[:preferred_username].blank?

    account_data = {}

    # Restore shared mailbox information from session and clean it up.
    if params[:shared_mailbox].present?
      account_data[:shared_mailbox] = params[:shared_mailbox]
    end

    channel_options = {
      inbound:  channel_options_inbound(user_data, account_data),
      outbound: channel_options_outbound(user_data, account_data),
      auth:     response.merge(
        provider:      provider_name,
        type:          'XOAUTH2',
        client_id:     external_credential.credentials[:client_id],
        client_secret: external_credential.credentials[:client_secret],
        client_tenant: external_credential.credentials[:client_tenant],
      ),
    }

    if params[:channel_id]
      existing_channel = Channel.where(area: channel_area).find(params[:channel_id])

      # Check if current user of the channel is matching the user from the token.
      #   Allow mismatch in case of a shared mailbox, since multiple users may be able access the same mailbox.
      #   In this case, inbound probe should verify if everything still works as expected.
      token_user     = user_data[:preferred_username]&.downcase
      inbound_user   = channel_user(existing_channel, :inbound)&.downcase
      outbound_user  = channel_user(existing_channel, :outbound)&.downcase
      shared_mailbox = channel_shared_mailbox(existing_channel)
      if ((inbound_user.present? && inbound_user != token_user) || (outbound_user.present? && outbound_user != token_user)) && shared_mailbox.blank?
        return "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/#{provider_name}/error/user_mismatch/channel/#{existing_channel.id}"
      end

      channel_options[:inbound][:options][:shared_mailbox] = shared_mailbox if shared_mailbox.present?
      channel_options[:inbound][:options][:folder]         = existing_channel.options[:inbound][:options][:folder]
      channel_options[:inbound][:options][:keep_on_server] = existing_channel.options[:inbound][:options][:keep_on_server]

      existing_channel.update!(
        options: channel_options,
      )

      existing_channel.refresh_xoauth2!

      return existing_channel
    end

    if channel_migration_possible?
      migration_channel = find_migration_channel(user_data)

      return execute_channel_migration(migrate_channel, channel_options) if migration_channel
    end

    email_address = {
      name:  "#{Setting.get('product_name')} Support",
      email: account_data[:shared_mailbox] || user_data[:preferred_username],
    }

    existing_email_address = EmailAddress.where(email: email_address[:email])

    # Check if a bound address with the same email already exists.
    if existing_email_address.where.not(channel: nil).exists?
      return "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/#{provider_name}/error/duplicate_email_address/param/#{CGI.escapeURIComponent(email_address[:email])}"
    end

    # create channel
    channel = Channel.create!(
      area:          channel_area,
      group_id:      Group.first.id,
      options:       channel_options,
      active:        false,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # Assign an email address to the channel by either creating a new or repurposing an existing one.
    if existing_email_address.exists?
      existing_email_address.update!(
        channel_id:    channel.id,
        name:          email_address[:name],
        email:         email_address[:email],
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    else
      EmailAddress.create_or_update(
        channel_id:    channel.id,
        name:          email_address[:name],
        email:         email_address[:email],
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    channel
  end

  def self.generate_authorize_url(credentials, scope = authorize_scope)
    # TODO: should we add recoomended "state" parameter here for security reasons?
    params = {
      'client_id'     => credentials[:client_id],
      'redirect_uri'  => ExternalCredential.callback_url(provider_name),
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

    response = UserAgent.post(uri.to_s, params)
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
      redirect_uri:  ExternalCredential.callback_url(provider_name),
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

    response = UserAgent.post(uri.to_s, params)
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

  def self.channel_user(channel, key)
    channel.options.dig(key.to_sym, :options, :user)
  end

  def self.channel_shared_mailbox(channel)
    channel.options.dig(:inbound, :options, :shared_mailbox)
  end

  def self.user_info(id_token)
    split = id_token.split('.')[1]
    return if split.blank?

    JSON.parse(Base64.decode64(split)).symbolize_keys
  end
end
