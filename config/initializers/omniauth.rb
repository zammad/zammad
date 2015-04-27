Rails.application.config.middleware.use OmniAuth::Builder do

  # twitter database connect 
  provider :twitter_database, 'not_change_will_be_set_by_databse', 'not_change_will_be_set_by_databse',
    client_options: { authorize_path: '/oauth/authorize', site: 'https://api.twitter.com' }

  # facebook database connect
  provider :facebook_database, 'not_change_will_be_set_by_databse', 'not_change_will_be_set_by_databse'

  # linkedin database connect
  provider :linked_in_database, 'not_change_will_be_set_by_databse', 'not_change_will_be_set_by_databse'

  # google database connect
  provider :google_oauth2_database, 'not_change_will_be_set_by_databse', 'not_change_will_be_set_by_databse',
    authorize_options: { access_type: 'online', approval_prompt: '' }

end
