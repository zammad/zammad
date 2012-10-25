$ = jQuery.sub()

class Index extends App.Controller
  events:
    'submit #login': 'login',

  constructor: ->
    super
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
      if Config[provider.config] is true || Config[provider.config] is "true"
        auth_providers.push provider

    @html App.view('login')(
      item:           data,
      auth_providers: auth_providers,
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

    # set avatar
    if !data.session.image
      data.session.image = 'http://placehold.it/48x48'

    # update config
    for key, value of data.config
      window.Config[key] = value

    # store user data
    for key, value of data.session
      window.Session[key] = value

    # refresh default collections
    for key, value of data.default_collections
      App[key].refresh( value, options: { clear: true } )

    # rebuild navbar with user data
    App.Event.trigger 'navrebuild', data.session

    # update websocked auth info
    App.WebSocket.auth()

    # rebuild navbar with ticket overview counter
    App.WebSocket.send( event: 'navupdate_ticket_overview' )

    # add notify
    App.Event.trigger 'notify:removeall'
    App.Event.trigger 'notify', {
      type: 'success',
      msg: App.i18n.translateContent('Login successfully! Have a nice day!'),
    }

    # redirect to #
    if window.Config['requested_url'] isnt ''
      @navigate window.Config['requested_url']

      # reset
      window.Config['requested_url'] = ''
    else
      @navigate '#/'

  error: (xhr, statusText, error) =>
    console.log 'login:error'

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

Config.Routes['login'] = Index
