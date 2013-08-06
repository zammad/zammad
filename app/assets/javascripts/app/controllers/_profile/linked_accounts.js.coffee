class Index extends App.Controller
  events:
    'click [data-type="remove"]': 'remove'

  constructor: ->
    super
    return if !@authenticate()
    @render()

  render: =>
    auth_provider_all = {
      facebook: {
        key:    'facebook' 
        url:    '/auth/facebook',
        name:   'Facebook',
        config: 'auth_facebook',
      },
      twitter: {
        key:    'twitter'
        url:    '/auth/twitter',
        name:   'Twitter',
        config: 'auth_twitter',
      },
      linkedin: {
        key:    'linkedin'
        url:    '/auth/linkedin',
        name:   'LinkedIn',
        config: 'auth_linkedin',
      },
      google_oauth2: {
        key:    'google_oauth2'
        url:    '/auth/google_oauth2',
        name:   'Google',
        config: 'auth_google_oauth2',
      },
    }
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get( provider.config ) is true || @Config.get( provider.config ) is "true"
        auth_providers.push provider

    @html App.view('profile/linked_accounts')(
      user:           App.Session.all()
      auth_providers: auth_providers
    )

  remove: (e) =>
    e.preventDefault()
    provider = $(e.target).data('provider')
    uid      = $(e.target).data('uid')

    # get data
    App.Com.ajax(
      id:   'account'
      type: 'DELETE'
      url:  @Config.get('api_path') + '/users/account'
      data: JSON.stringify({ provider: provider, uid: uid })
      processData: true
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>
    App.Auth.loginCheck()
    @render()
    @notify(
      type: 'success'
      msg:  App.i18n.translateContent( 'Successfully!' )
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'LinkedAccounts', { prio: 3000, name: 'Linked Accunts', parent: '#profile', target: '#profile/linked', controller: Index }, 'NavBarProfile' )

