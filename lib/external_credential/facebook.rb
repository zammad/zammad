# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Facebook

  def self.app_verify(params)
    request_account_to_link(params, false)
    params
  end

  def self.request_account_to_link(credentials = {}, app_required = true)
    external_credential = ExternalCredential.find_by(name: 'facebook')
    raise Exceptions::UnprocessableEntity, __('No Facebook app configured!') if !external_credential && app_required

    if external_credential
      if credentials[:application_id].blank?
        credentials[:application_id] = external_credential.credentials['application_id']
      end
      if credentials[:application_secret].blank?
        credentials[:application_secret] = external_credential.credentials['application_secret']
      end
    end

    raise Exceptions::UnprocessableEntity, __("The required parameter 'application_id' is missing.") if credentials[:application_id].blank?
    raise Exceptions::UnprocessableEntity, __("The required parameter 'application_secret' is missing.") if credentials[:application_secret].blank?

    oauth = Koala::Facebook::OAuth.new(
      credentials[:application_id],
      credentials[:application_secret],
      ExternalCredential.callback_url('facebook'),
    )
    oauth.get_app_access_token.inspect
    state = SecureRandom.uuid
    {
      request_token: state,
      authorize_url: oauth.url_for_oauth_code(permissions: 'pages_manage_metadata, pages_messaging, pages_show_list, pages_read_engagement', state: state),
    }
  end

  def self.link_account(_request_token, params)
    #    fail if request_token.params[:oauth_token] != params[:state]
    external_credential = ExternalCredential.find_by(name: 'facebook')
    raise Exceptions::UnprocessableEntity, __('No Facebook app configured!') if !external_credential

    oauth = Koala::Facebook::OAuth.new(
      external_credential.credentials['application_id'],
      external_credential.credentials['application_secret'],
      ExternalCredential.callback_url('facebook'),
    )

    access_token = oauth.get_access_token(params[:code])
    client = Koala::Facebook::API.new(access_token)
    user = client.get_object('me')
    pages = client.get_connections('me', 'accounts').map do |page|
      {
        id:           page['id'],
        name:         page['name'],
        access_token: page['access_token']
      }
    end

    # Fallback for Facebook Login for Business with granular permissions:
    # /me/accounts may return empty even when pages are authorized, because
    # "Facebook Login for Business" grants page access via granular_scopes
    # rather than the traditional /me/accounts endpoint.
    # In this case, extract page IDs from the token's granular_scopes and
    # query each page individually.
    if pages.empty?
      app_token = external_credential.credentials['application_id'] + '|' + external_credential.credentials['application_secret']
      app_client = Koala::Facebook::API.new(app_token)
      token_info = app_client.debug_token(access_token)
      granular = token_info.dig('data', 'granular_scopes') || []
      page_ids = granular.select { |s| s['scope'] == 'pages_show_list' }
                         .flat_map { |s| s['target_ids'] || [] }
                         .uniq
      pages = page_ids.filter_map do |pid|
        page_data = client.get_object(pid, fields: 'id,name,access_token')
        { id: page_data['id'], name: page_data['name'], access_token: page_data['access_token'] }
      rescue => e
        Rails.logger.warn "Facebook: failed to fetch page #{pid} via granular_scopes fallback: #{e.message}"
        nil
      end
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
