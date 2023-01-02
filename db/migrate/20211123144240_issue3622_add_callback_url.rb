# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3622AddCallbackUrl < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    configs = {
      auth_twitter_credentials:             'auth_twitter',
      auth_facebook_credentials:            'auth_facebook',
      auth_google_oauth2_credentials:       'auth_google_oauth2',
      auth_linkedin_credentials:            'auth_linkedin',
      auth_github_credentials:              'auth_github',
      auth_gitlab_credentials:              'auth_gitlab',
      auth_microsoft_office365_credentials: 'auth_microsoft_office365',
      auth_weibo_credentials:               'auth_weibo',
      auth_saml_credentials:                'auth_saml',
    }
    configs.each do |key, value|
      config = Setting.find_by(name: key)
      config.options['form'] << {
        'display'  => 'Your callback URL',
        'null'     => true,
        'name'     => 'callback_url',
        'tag'      => 'auth_provider',
        'provider' => value
      }
      config.save!
    end
  end
end
