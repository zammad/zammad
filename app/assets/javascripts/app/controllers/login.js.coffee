class Index extends App.ControllerContent
  events:
    'submit #login': 'login',

  constructor: ->
    super

    # navigate to # if sesstion if exists
    if @Session.get( 'id' )
      @navigate '#'
      return

    @title 'Sign in'
    @render()
    @navupdate '#login'

  render: (data = {}) ->
    auth_provider_all = {
      facebook: {
        url:    '/auth/facebook',
        name:   'Facebook',
        config: 'auth_facebook',
      },
      twitter: {
        url:    '/auth/twitter',
        name:   'Twitter',
        config: 'auth_twitter',
      },
      linkedin: {
        url:    '/auth/linkedin',
        name:   'LinkedIn',
        config: 'auth_linkedin',
      },
      google_oauth2: {
        url:    '/auth/google_oauth2',
        name:   'Google',
        config: 'auth_google_oauth2',
      },
    }
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get( provider.config ) is true || @Config.get( provider.config ) is "true"
        auth_providers.push provider

    @html App.view('login')(
      item:           data
      auth_providers: auth_providers
    )

    # set focus
    if !$(@el).find('[name="username"]').val()
      $(@el).find('[name="username"]').focus()
    else
      $(@el).find('[name="password"]').focus()

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
      data:    params,
      success: @success
      error:   @error,
    )

  success: (data, status, xhr) =>
    @log 'login:success', data

    # rebuild navbar with ticket overview counter
    App.WebSocket.send( event: 'navupdate_ticket_overview' )

    # add notify
    App.Event.trigger 'notify:removeall'
    App.Event.trigger 'notify', {
      type: 'success',
      msg: App.i18n.translateContent('Login successfully! Have a nice day!'),
    }

    # redirect to #
    requested_url = @Config.get( 'requested_url' )
    if requested_url isnt ''
      console.log("REDIRECT to '#{requested_url}'")
      @navigate requested_url

      # reset
      @Config.set( 'requested_url', '' )
    else
      console.log("REDIRECT to -#/-")
      @navigate '#/'

  error: (xhr, statusText, error) =>

    # add notify
    App.Event.trigger 'notify:removeall'
    App.Event.trigger 'notify', {
      type: 'error',
      msg: App.i18n.translateContent('Wrong Username and Password combination.'), 
    }

    # rerender login page
    @render(
      username: @username
    )

    # login shake
    @delay(
      => @shake( @el.find('#login') ),
      700
    )

App.Config.set( 'login', Index, 'Routes' )
