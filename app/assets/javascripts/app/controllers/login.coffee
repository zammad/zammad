class Login extends App.ControllerFullPage
  events:
    'submit #login': 'login'
  className: 'login'

  constructor: ->
    super

    # redirect to getting started if setup is not done
    if !@Config.get('system_init_done')
      @navigate '#getting_started'
      return

    # navigate to # if session if exists
    if @Session.get()
      @navigate '#'
      return

    # show session timeout message on login screen
    data = {}
    if window.location.hash is '#session_timeout'
      data = {
        errorMessage: App.i18n.translateContent('Due to inactivity you are automatically logged out.')
      }

    @title 'Sign in'
    @render(data)
    @navupdate '#login'

    # observe config changes related to login page
    @controllerBind('config_update_local', (data) =>
      return if !data.name.match(/^maintenance/) &&
        !data.name.match(/^auth/) &&
        data.name != 'user_lost_password' &&
        data.name != 'user_create_account' &&
        data.name != 'product_name' &&
        data.name != 'product_logo' &&
        data.name != 'fqdn'
      @render()
      'rerender'
    )
    @controllerBind('ui:rerender', =>
      @render()
    )

  render: (data = {}) ->
    auth_provider_all = App.Config.get('auth_provider_all')
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get(provider.config) is true || @Config.get(provider.config) is 'true'
        auth_providers.push provider

    @replaceWith App.view('login')(
      item:           data
      logoUrl:        @logoUrl()
      auth_providers: auth_providers
    )

    # set focus to username or password
    if !@$('[name="username"]').val()
      @$('[name="username"]').focus()
    else
      @$('[name="password"]').focus()

    # scroll to top
    @scrollTo()

  login: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @formDisable(e)
    params = @formParam(e.target)

    # remember username
    @username = params['username']

    # session create with login/password
    App.Auth.login(
      data:    params
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>

    # redirect to #
    @log 'notice', 'REDIRECT to -#/-'
    @navigate '#/'

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    errorMessage = App.i18n.translateContent(details.error || 'Could not process your request')

    # rerender login page
    @render(
      username:     @username
      errorMessage: errorMessage
    )

    # login shake
    @delay(
      => @shake( @$('.hero-unit') )
      600
    )

App.Config.set('login', Login, 'Routes')
App.Config.set('session_timeout', Login, 'Routes')
