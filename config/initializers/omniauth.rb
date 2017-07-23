Rails.application.config.middleware.use OmniAuth::Builder do

  # twitter database connect
  provider :twitter_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
    client_options: {
      authorize_path: '/oauth/authorize',
      site: 'https://api.twitter.com',
    }
  }

  # facebook database connect
  provider :facebook_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'

  # linkedin database connect
  provider :linked_in_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'

  # google database connect
  provider :google_oauth2_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
    authorize_options: {
      access_type: 'online',
      approval_prompt: '',
    }
  }

  # github database connect
  provider :github_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'

  # gitlab database connect
  provider :gitlab_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
    client_options: {
      site: 'https://not_change_will_be_set_by_database',
      authorize_url: '/oauth/authorize',
      token_url: '/oauth/token'
    },
  }

  # microsoft_office365 database connect
  provider :microsoft_office365_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database'

  # oauth2 database connect
  provider :oauth2_database, 'not_change_will_be_set_by_database', 'not_change_will_be_set_by_database', {
    client_options: {
      site: 'https://not_change_will_be_set_by_database',
      authorize_url: '/oauth/authorize',
      token_url: '/oauth/token',
    },
  }

end
