class ExternalCredential::Twitter

  def self.app_verify(params)
    attributes = {
      consumer_key:    params[:consumer_key],
      consumer_secret: params[:consumer_secret],
    }
    request_account_to_link('', attributes)
    attributes
  end

  def self.request_account_to_link(callback_url, credentials = {})
    external_credential = ExternalCredential.find_by(name: 'twitter')
    consumer = OAuth::Consumer.new(
      credentials[:consumer_key] || external_credential.credentials[:consumer_key],
      credentials[:consumer_secret] || external_credential.credentials[:consumer_secret], {
        site: 'https://api.twitter.com'
      })
    request_token = consumer.get_request_token(oauth_callback: callback_url)
    {
      request_token: request_token,
      authorize_url: request_token.authorize_url,
    }
  end

  def self.link_account(request_token, params)
    fail if request_token.params[:oauth_token] != params[:oauth_token]

    external_credential = ExternalCredential.find_by(name: 'twitter')
    access_token = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
    client = Twitter::REST::Client.new(
      consumer_key: external_credential.credentials[:consumer_key],
      consumer_secret: external_credential.credentials[:consumer_secret],
      access_token: access_token.token,
      access_token_secret: access_token.secret,
    )
    user = client.user

    # create channel
    Channel.create(
      area: 'Twitter::Account',
      options: {
        adapter: 'twitter',
        user: {
          id: user.id,
          screen_name: user.screen_name,
        },
        auth: {
          external_credential_id: external_credential.id,
          oauth_token:            access_token.token,
          oauth_token_secret:     access_token.secret,
        },
        sync: {
          search: [],
          mentions: {},
          direct_messages: {}
        }
      },
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

end
