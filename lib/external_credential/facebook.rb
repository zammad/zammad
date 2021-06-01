# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredential::Facebook

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: 'facebook')
    raise Exceptions::UnprocessableEntity, 'No facebook app configured!' if !external_credential && app_required

    if external_credential
      if credentials[:application_id].blank?
        credentials[:application_id] = external_credential.credentials['application_id']
      end
      if credentials[:application_secret].blank?
        credentials[:application_secret] = external_credential.credentials['application_secret']
      end
    end

    raise Exceptions::UnprocessableEntity, 'No application_id param!' if credentials[:application_id].blank?
    raise Exceptions::UnprocessableEntity, 'No application_secret param!' if credentials[:application_secret].blank?

    oauth = Koala::Facebook::OAuth.new(
      credentials[:application_id],
      credentials[:application_secret],
      ExternalCredential.callback_url('facebook'),
    )
    oauth.get_app_access_token.inspect
    state = rand(999_999_999_999).to_s
    {
      request_token: state,
      #authorize_url: oauth.url_for_oauth_code(permissions: 'publish_pages, manage_pages, user_posts', state: state),
      #authorize_url: oauth.url_for_oauth_code(permissions: 'publish_pages, manage_pages', state: state),
      authorize_url: oauth.url_for_oauth_code(permissions: 'pages_manage_posts, pages_manage_engagement, pages_manage_metadata, pages_read_engagement, pages_read_user_content', state: state),
    }
  end

  def self.link_account(_request_token, params)
    #    fail if request_token.params[:oauth_token] != params[:state]
    external_credential = ExternalCredential.find_by(name: 'facebook')
    raise Exceptions::UnprocessableEntity, 'No facebook app configured!' if !external_credential

    oauth = Koala::Facebook::OAuth.new(
      external_credential.credentials['application_id'],
      external_credential.credentials['application_secret'],
      ExternalCredential.callback_url('facebook'),
    )

    access_token = oauth.get_access_token(params[:code])
    client = Koala::Facebook::API.new(access_token)
    user = client.get_object('me')
    #p client.get_connections('me', 'accounts').inspect
    pages = []
    client.get_connections('me', 'accounts').each do |page|
      pages.push(
        id:           page['id'],
        name:         page['name'],
        access_token: page['access_token'],
      )
    end

    # check if account already exists
    Channel.where(area: 'Facebook::Account').each do |channel|
      next if !channel.options
      next if !channel.options['user']
      next if !channel.options['user']['id']
      next if channel.options['user']['id'] != user['id']

      channel.options['auth']['access_token'] = access_token
      channel.options['pages'] = pages
      channel.save!
      return channel
    end

    # create channel
    Channel.create!(
      area:          'Facebook::Account',
      options:       {
        adapter: 'facebook',
        auth:    {
          access_token: access_token
        },
        user:    user,
        pages:   pages,
        sync:    {
          pages: [],
        }
      },
      active:        true,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

end
