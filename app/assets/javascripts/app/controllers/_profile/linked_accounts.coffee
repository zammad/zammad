class ProfileLinkedAccounts extends App.ControllerSubContent
  requiredPermission: 'user_preferences.linked_accounts'
  header: 'Linked Accounts'
  events:
    'click .js-add':    'add'
    'click .js-remove': 'remove'

  constructor: ->
    super
    @render()

  render: =>
    auth_provider_all = App.Config.get('auth_provider_all')
    auth_providers = {}
    for key, provider of auth_provider_all
      if @Config.get(provider.config) is true || @Config.get(provider.config) is 'true'
        auth_providers[key] = provider

    @html App.view('profile/linked_accounts')(
      user:           App.Session.get()
      auth_providers: auth_providers
    )

  add: (e) =>
    e.preventDefault()
    key = $(e.target).data('key')
    @el.find(".js-addForm-#{key}").submit()

  remove: (e) =>
    e.preventDefault()
    provider = $(e.target).data('provider')
    uid      = $(e.target).data('uid')

    # get data
    @ajax(
      id:          'account'
      type:        'DELETE'
      url:         "#{@apiPath}/users/account"
      data:        JSON.stringify(provider: provider, uid: uid)
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    @notify(
      type: 'success'
      msg:  App.i18n.translateContent('Successful!')
    )
    update = =>
      @render()
    App.User.full(@Session.get('id'), update, true)

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('LinkedAccounts', { prio: 4000, name: 'Linked Accounts', parent: '#profile', target: '#profile/linked', controller: ProfileLinkedAccounts, permission: ['user_preferences.linked_accounts'] }, 'NavBarProfile')
App.Config.set('auth_provider_all', {
  facebook:
    url:    '/auth/facebook'
    name:   'Facebook'
    config: 'auth_facebook'
    class:  'facebook'
  twitter:
    url:    '/auth/twitter'
    name:   'Twitter'
    config: 'auth_twitter'
    class:  'twitter'
  linkedin:
    url:    '/auth/linkedin'
    name:   'LinkedIn'
    config: 'auth_linkedin'
    class:  'linkedin'
  github:
    url:    '/auth/github'
    name:   'GitHub'
    config: 'auth_github'
    class:  'github'
  gitlab:
    url:    '/auth/gitlab'
    name:   'GitLab'
    config: 'auth_gitlab'
    class:  'gitlab'
  microsoft_office365:
    url:    '/auth/microsoft_office365'
    name:   'Office 365'
    config: 'auth_microsoft_office365'
    class:  'office365'
  google_oauth2:
    url:    '/auth/google_oauth2'
    name:   'Google'
    config: 'auth_google_oauth2'
    class:  'google'
  weibo:
    url:    '/auth/weibo'
    name:   'Weibo'
    config: 'auth_weibo'
    class:  'weibo'
  saml:
    url:    '/auth/saml'
    name:   'SAML'
    config: 'auth_saml'
    class:  'saml'
  sso:
    url:    '/auth/sso'
    name:   'SSO'
    config: 'auth_sso'
    class:  'sso'
})
