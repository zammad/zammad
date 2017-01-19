class ExternalCredential::Twitter

  def self.app_verify(params)
    request_account_to_link(params)
    params
  end

  def self.request_account_to_link(credentials = {})
    external_credential = ExternalCredential.find_by(name: 'twitter')
    if !credentials[:consumer_key]
      credentials[:consumer_key] = external_credential.credentials['consumer_key']
    end
    if !credentials[:consumer_secret]
      credentials[:consumer_secret] = external_credential.credentials['consumer_secret']
    end
    consumer = OAuth::Consumer.new(
      credentials[:consumer_key],
      credentials[:consumer_secret], {
        site: 'https://api.twitter.com'
      }
    )
    request_token = consumer.get_request_token(oauth_callback: ExternalCredential.callback_url('twitter'))
    {
      request_token: request_token,
      authorize_url: request_token.authorize_url,
    }
  end

  def self.link_account(request_token, params)
    raise if request_token.params[:oauth_token] != params[:oauth_token]
    external_credential = ExternalCredential.find_by(name: 'twitter')
    access_token = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
    client = Twitter::REST::Client.new(
      consumer_key: external_credential.credentials[:consumer_key],
      consumer_secret: external_credential.credentials[:consumer_secret],
      access_token: access_token.token,
      access_token_secret: access_token.secret,
    )
    user = client.user

    # check if account already exists
    Channel.where(area: 'Twitter::Account').each { |channel|
      next if !channel.options
      next if !channel.options['user']
      next if !channel.options['user']['id']
      next if channel.options['user']['id'] != user['id']

      # update access_token
      channel.options['auth']['external_credential_id'] = external_credential.id
      channel.options['auth']['oauth_token'] = access_token.token
      channel.options['auth']['oauth_token_secret'] = access_token.secret
      channel.save
      return channel
    }

    # create channel
    Channel.create(
      area: 'Twitter::Account',
      options: {
        adapter: 'twitter',
        user: {
          id: user.id,
          screen_name: user.screen_name,
          name: user.name,
        },
        auth: {
          external_credential_id: external_credential.id,
          oauth_token:            access_token.token,
          oauth_token_secret:     access_token.secret,
        },
        sync: {
          limit: 20,
          search: [],
          mentions: {},
          direct_messages: {},
          track_retweets: false
        }
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

end
