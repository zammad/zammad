Rails.application.config.middleware.use OmniAuth::Builder do

  # twitter database connect 
  provider :twitter_database, 'xx', 'xx',
    :client_options => { :authorize_path => '/oauth/authorize', :site => 'https://api.twitter.com' }

  # facebook database connect
  provider :facebook_database, 'xx', 'xx'

  # linkedin database connect
#  provider :linked_in_database, 'xx', 'xx'

end
