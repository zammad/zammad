class Index extends App.ControllerContent
  events:
    'submit #login': 'login'

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

    @navHide()

    @title 'Sign in'
    @render()
    @navupdate '#login'

    # observe config changes related to login page
    @bind('config_update_local', (data) =>
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
    @bind('ui:rerender', =>
      @render()
    )

  render: (data = {}) ->
    auth_provider_all = App.Config.get('auth_provider_all')
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get(provider.config) is true || @Config.get(provider.config) is 'true'
        auth_providers.push provider

    @html App.view('login')(
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
    requested_url = @Config.get('requested_url')
    if requested_url && requested_url isnt '#login' && requested_url isnt '#logout'
      @log 'notice', "REDIRECT to '#{requested_url}'"
      @navigate requested_url

      # reset
      @Config.set('requested_url', '')
    else
      @log 'notice', 'REDIRECT to -#/-'
      @navigate '#/'

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    # add notify
    @notify
      type:      'error'
      msg:       App.i18n.translateContent(details.error || 'Wrong Username or Password combination.')
      removeAll: true

    # rerender login page
    @render(
      username: @username
    )

    # login shake
    @delay(
      => @shake( @$('.hero-unit') )
      600
    )

App.Config.set('login', Index, 'Routes')
