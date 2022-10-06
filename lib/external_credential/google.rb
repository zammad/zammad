# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Google

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: 'google')
    raise Exceptions::UnprocessableEntity, __('There is no Google app configured.') if !external_credential && app_required

    if external_credential
      if credentials[:client_id].blank?
        credentials[:client_id] = external_credential.credentials['client_id']
      end
      if credentials[:client_secret].blank?
        credentials[:client_secret] = external_credential.credentials['client_secret']
      end
    end

    raise Exceptions::UnprocessableEntity, __("The required parameter 'client_id' is missing.") if credentials[:client_id].blank?
    raise Exceptions::UnprocessableEntity, __("The required parameter 'client_secret' is missing.") if credentials[:client_secret].blank?

    authorize_url = generate_authorize_url(credentials[:client_id])

    {
      authorize_url: authorize_url,
    }
  end

  def self.link_account(_request_token, params)
    external_credential = ExternalCredential.find_by(name: 'google')
    raise Exceptions::UnprocessableEntity, __('There is no Google app configured.') if !external_credential
    raise Exceptions::UnprocessableEntity, __("The required parameter 'code' is missing.") if !params[:code]

    response = authorize_tokens(external_credential.credentials[:client_id], external_credential.credentials[:client_secret], params[:code])
    %w[refresh_token access_token expires_in scope token_type id_token].each do |key|
      raise Exceptions::UnprocessableEntity, "No #{key} for authorization request found!" if response[key.to_sym].blank?
    end

    user_data = user_info(response[:id_token])
    raise Exceptions::UnprocessableEntity, __("User email could not be extracted from 'id_token'.") if user_data[:email].blank?

    channel_options = {
      inbound:  {
        adapter: 'imap',
        options: {
          auth_type: 'XOAUTH2',
          host:      'imap.gmail.com',
          ssl:       'ssl',
          user:      user_data[:email],
        },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host:           'smtp.gmail.com',
          port:           465,
          ssl:            true,
          user:           user_data[:email],
          authentication: 'xoauth2',
        },
      },
      auth:     response.merge(
        provider:      'google',
        type:          'XOAUTH2',
        client_id:     external_credential.credentials[:client_id],
        client_secret: external_credential.credentials[:client_secret],
      ),
    }

    if params[:channel_id]
      existing_channel = Channel.where(area: 'Google::Account').find(params[:channel_id])

      existing_channel.update!(
        options: channel_options,
      )

      existing_channel.refresh_xoauth2!

      return existing_channel
    end

    migrate_channel = nil
    Channel.where(area: 'Email::Account').find_each do |channel|
      next if channel.options.dig(:inbound, :options, :host)&.downcase != 'imap.gmail.com'
      next if channel.options.dig(:outbound, :options, :host)&.downcase != 'smtp.gmail.com'
      next if channel.options.dig(:outbound, :options, :user)&.downcase != user_data[:email].downcase && channel.options.dig(:outbound, :email)&.downcase != user_data[:email].downcase

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
        area:         'Google::Account',
        options:      channel_options.merge(backup_imap_classic: backup),
        last_log_in:  nil,
        last_log_out: nil,
      )

      return migrate_channel
    end

    email_addresses = user_aliases(response)
    email_addresses.unshift({
                              realname: "#{Setting.get('product_name')} Support",
                              email:    user_data[:email],
                            })

    email_addresses.each do |email|
      next if !EmailAddress.exists?(email: email[:email])

      raise Exceptions::UnprocessableEntity, "Duplicate email address or email alias #{email[:email]} found!"
    end

    # create channel
    channel = Channel.create!(
      area:          'Google::Account',
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

  def self.generate_authorize_url(client_id, scope = 'openid email profile https://mail.google.com/')

    params = {
      'client_id'     => client_id,
      'redirect_uri'  => ExternalCredential.callback_url('google'),
      'scope'         => scope,
      'response_type' => 'code',
      'access_type'   => 'offline',
      'prompt'        => 'consent',
    }

    uri = URI::HTTPS.build(
      host:  'accounts.google.com',
      path:  '/o/oauth2/auth',
      query: params.to_query
    )

    uri.to_s
  end

  def self.authorize_tokens(client_id, client_secret, authorization_code)
    params = {
      'client_secret' => client_secret,
      'code'          => authorization_code,
      'grant_type'    => 'authorization_code',
      'client_id'     => client_id,
      'redirect_uri'  => ExternalCredential.callback_url('google'),
    }

    uri = URI::HTTPS.build(
      host: 'accounts.google.com',
      path: '/o/oauth2/token',
    )

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

  def self.refresh_token(token)
    return token if token[:created_at] >= 50.minutes.ago

    params = {
      'client_id'     => token[:client_id],
      'client_secret' => token[:client_secret],
      'refresh_token' => token[:refresh_token],
      'grant_type'    => 'refresh_token',
    }
    uri = URI::HTTPS.build(
      host: 'accounts.google.com',
      path: '/o/oauth2/token',
    )

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

    token.merge(
      created_at:   Time.zone.now,
      access_token: result['access_token'],
    ).symbolize_keys
  end

  def self.user_aliases(token)
    uri = URI.parse('https://www.googleapis.com/gmail/v1/users/me/settings/sendAs')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.get(uri.request_uri, { 'Authorization' => "#{token[:token_type]} #{token[:access_token]}" })
    if response.code != 200 && response.body.blank?
      Rails.logger.error "Request failed! (code: #{response.code})"
      raise "Request failed! (code: #{response.code})"
    end

    result = JSON.parse(response.body)
    if result['error'] && response.code != 200
      Rails.logger.error "Request failed! ERROR: #{result['error']['message']}"
      raise "Request failed! ERROR: #{result['error']['message']}"
    end

    aliases = []
    result['sendAs'].each do |row|
      next if row['isPrimary']
      next if !row['verificationStatus']
      next if row['verificationStatus'] != 'accepted'

      aliases.push({
                     realname: row['displayName'],
                     email:    row['sendAsEmail'],
                   })
    end

    aliases
  end

  def self.user_info(id_token)
    split = id_token.split('.')[1]
    return if split.blank?

    JSON.parse(Base64.decode64(split)).symbolize_keys
  end

end
