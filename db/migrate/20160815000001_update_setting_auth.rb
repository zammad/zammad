
class UpdateSettingAuth < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    change_column :settings, :preferences, :text, limit: 200.kilobytes + 1, null: true
    change_column :settings, :state_current, :text, limit: 200.kilobytes + 1, null: true

    Setting.connection.schema_cache.clear!
    Setting.reset_column_information

    Setting.create_if_not_exists(
      title: 'Authentication via %s',
      name: 'auth_ldap',
      area: 'Security::Authentication',
      description: 'Enables user authentication via %s.',
      preferences: {
        title_i18n: ['LDAP'],
        description_i18n: ['LDAP']
      },
      state: {
        adapter: 'Auth::Ldap',
        host: 'localhost',
        port: 389,
        bind_dn: 'cn=Manager,dc=example,dc=org',
        bind_pw: 'example',
        uid: 'mail',
        base: 'dc=example,dc=org',
        always_filter: '',
        always_roles: %w(Admin Agent),
        always_groups: ['Users'],
        sync_params: {
          firstname: 'sn',
          lastname: 'givenName',
          email: 'mail',
          login: 'mail',
        },
      },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_twitter',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_twitter',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_twitter_credentials'],
        title_i18n: ['Twitter'],
        description_i18n: ['Twitter', 'Twitter Developer Site', 'https://dev.twitter.com/apps']
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'Twitter App Credentials',
      name: 'auth_twitter_credentials',
      area: 'Security::ThirdPartyAuthentication::Twitter',
      description: 'App credentials for Twitter.',
      options: {
        form: [
          {
            display: 'Twitter Key',
            null: true,
            name: 'key',
            tag: 'input',
          },
          {
            display: 'Twitter Secret',
            null: true,
            name: 'secret',
            tag: 'input',
          },
        ],
      },
      state: {},
      frontend: false
    )
    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_facebook',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_facebook',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_facebook_credentials'],
        title_i18n: ['Facebook'],
        description_i18n: ['Facebook', 'Facebook Developer Site', 'https://developers.facebook.com/apps/']
      },
      state: false,
      frontend: true
    )

    Setting.create_or_update(
      title: 'Facebook App Credentials',
      name: 'auth_facebook_credentials',
      area: 'Security::ThirdPartyAuthentication::Facebook',
      description: 'App credentials for Facebook.',
      options: {
        form: [
          {
            display: 'App ID',
            null: true,
            name: 'app_id',
            tag: 'input',
          },
          {
            display: 'App Secret',
            null: true,
            name: 'app_secret',
            tag: 'input',
          },
        ],
      },
      state: {},
      frontend: false
    )

    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_google_oauth2',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_google_oauth2',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_google_oauth2_credentials'],
        title_i18n: ['Google'],
        description_i18n: ['Google', 'Google API Console Site', 'https://console.developers.google.com/apis/credentials']
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'Google App Credentials',
      name: 'auth_google_oauth2_credentials',
      area: 'Security::ThirdPartyAuthentication::Google',
      description: 'Enables user authentication via Google.',
      options: {
        form: [
          {
            display: 'Client ID',
            null: true,
            name: 'client_id',
            tag: 'input',
          },
          {
            display: 'Client Secret',
            null: true,
            name: 'client_secret',
            tag: 'input',
          },
        ],
      },
      state: {},
      frontend: false
    )

    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_linkedin',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_linkedin',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_linkedin_credentials'],
        title_i18n: ['LinkedIn'],
        description_i18n: ['LinkedIn', 'Linkedin Developer Site', 'https://www.linkedin.com/developer/apps']
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'LinkedIn App Credentials',
      name: 'auth_linkedin_credentials',
      area: 'Security::ThirdPartyAuthentication::Linkedin',
      description: 'Enables user authentication via LinkedIn.',
      options: {
        form: [
          {
            display: 'App ID',
            null: true,
            name: 'app_id',
            tag: 'input',
          },
          {
            display: 'App Secret',
            null: true,
            name: 'app_secret',
            tag: 'input',
          },
        ],
      },
      state: {},
      frontend: false
    )

    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_github',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_github',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_github_credentials'],
        title_i18n: ['Github'],
        description_i18n: ['Github', 'Github OAuth Applications', 'https://github.com/settings/applications']
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'Github App Credentials',
      name: 'auth_github_credentials',
      area: 'Security::ThirdPartyAuthentication::Github',
      description: 'Enables user authentication via Github.',
      options: {
        form: [
          {
            display: 'App ID',
            null: true,
            name: 'app_id',
            tag: 'input',
          },
          {
            display: 'App Secret',
            null: true,
            name: 'app_secret',
            tag: 'input',
          },
        ],
      },
      state: {},
      frontend: false
    )

    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_gitlab',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_gitlab',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_gitlab_credentials'],
        title_i18n: ['Gitlab'],
        description_i18n: ['Gitlab', 'Gitlab Applications', 'https://your-gitlab-host/admin/applications']
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'Gitlab App Credentials',
      name: 'auth_gitlab_credentials',
      area: 'Security::ThirdPartyAuthentication::Gitlab',
      description: 'Enables user authentication via Gitlab.',
      options: {
        form: [
          {
            display: 'App ID',
            null: true,
            name: 'app_id',
            tag: 'input',
          },
          {
            display: 'App Secret',
            null: true,
            name: 'app_secret',
            tag: 'input',
          },
          {
            display: 'Site',
            null: true,
            name: 'site',
            tag: 'input',
            placeholder: 'https://gitlab.YOURDOMAIN.com',
          },
        ],
      },
      state: {},
      frontend: false
    )

    Setting.create_or_update(
      title: 'Authentication via %s',
      name: 'auth_oauth2',
      area: 'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via Generic OAuth2. Register your app first,',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'auth_oauth2',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller: 'SettingsAreaSwitch',
        sub: ['auth_oauth2_credentials'],
        title_i18n: ['Generic OAuth2'],
      },
      state: false,
      frontend: true
    )
    Setting.create_or_update(
      title: 'Generic OAuth2 App Credentials',
      name: 'auth_oauth2_credentials',
      area: 'Security::ThirdPartyAuthentication::GenericOAuth',
      description: 'Enables user authentication via Generic OAuth2.',
      options: {
        form: [
          {
            display: 'Name',
            null: true,
            name: 'name',
            tag: 'input',
            placeholder: 'Some Provider Name',
          },
          {
            display: 'App ID',
            null: true,
            name: 'app_id',
            tag: 'input',
          },
          {
            display: 'App Secret',
            null: true,
            name: 'app_secret',
            tag: 'input',
          },
          {
            display: 'Site',
            null: true,
            name: 'site',
            tag: 'input',
            placeholder: 'https://gitlab.YOURDOMAIN.com',
          },
          {
            display: 'authorize_url',
            null: true,
            name: 'authorize_url',
            tag: 'input',
            placeholder: '/oauth/authorize',
          },
          {
            display: 'token_url',
            null: true,
            name: 'token_url',
            tag: 'input',
            placeholder: '/oauth/token',
          },
        ],
      },
      state: {},
      frontend: false
    )
    setting = Setting.find_by(name: 'product_logo')
    setting.preferences[:controller] = 'SettingsAreaLogo'
    setting.save

  end
end
